// Euphoria web loader (injected into web/index.html by tools/publish_web.sh).
// - Euphoria_v2.pck is split into parts (GitHub's 100 MB file limit): stream them back as one response.
// - Mobile browsers kill downloads when the tab goes to the background. Every file (.pck parts and .wasm)
//   is therefore streamed with RESUME: on a network error / stall / truncated body it waits until the tab
//   is visible again and continues from the last byte with an HTTP Range request (bypassing the HTTP cache,
//   so a broken cached copy can never block the next try).
(function () {
	const SOURCES = [
		{ re: /Euphoria_v2\.pck(\?|$)/, parts: __PARTS__, type: 'application/octet-stream' },
		{ re: /Euphoria_v2\.wasm(\?|$)/, parts: ['Euphoria_v2.wasm'], type: 'application/wasm' },
	];
	const STALL_MS = 20000; // no bytes for this long -> reconnect
	const MAX_FAILS = 15; // consecutive failures (while visible) before giving up
	const nativeFetch = window.fetch.bind(window);
	const net = window.__euphoriaNet = { reconnects: 0, onRetry: null, onResume: null };

	const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
	function waitVisible() {
		if (!document.hidden) {
			return Promise.resolve();
		}
		return new Promise((resolve) => {
			const f = () => {
				if (!document.hidden) {
					document.removeEventListener('visibilitychange', f);
					resolve();
				}
			};
			document.addEventListener('visibilitychange', f);
		});
	}
	function timeout(p, ms, onTimeout) {
		let t = null;
		return Promise.race([
			p.finally(() => clearTimeout(t)),
			new Promise((_, reject) => {
				t = setTimeout(() => {
					onTimeout();
					reject(new Error('stalled'));
				}, ms);
			}),
		]);
	}

	function resumableStream(parts) {
		let idx = 0; // current part
		let got = 0; // bytes of the current part already delivered
		let expect = -1; // full size of the current part (-1 = unknown)
		let skip = 0; // bytes to drop when the server ignored our Range
		let fails = 0;
		let fresh = false; // after a failure: bypass the HTTP cache
		let reader = null;
		let ctrl = null;

		async function fail(err) {
			try { if (ctrl) { ctrl.abort(); } } catch (e) { /* ignore */ }
			reader = null;
			const hidden = document.hidden;
			if (!hidden) {
				fails++;
			}
			if (fails > MAX_FAILS) {
				throw new Error('Koneksi terputus saat mengunduh ' + parts[idx] + ' (' + (err && err.message ? err.message : err) + ')');
			}
			fresh = true;
			net.reconnects++;
			if (net.onRetry) { net.onRetry(hidden, fails); }
			await waitVisible();
			await sleep(Math.min(800 * Math.max(1, fails), 6000));
			if (net.onResume) { net.onResume(); }
		}

		async function open() {
			for (;;) {
				await waitVisible();
				ctrl = new AbortController();
				const headers = {};
				if (got > 0) {
					headers['Range'] = 'bytes=' + got + '-';
				}
				try {
					const r = await timeout(nativeFetch(parts[idx], { headers: headers, signal: ctrl.signal, cache: fresh ? 'no-store' : 'default' }), STALL_MS, () => ctrl.abort());
					const enc = r.headers.get('Content-Encoding');
					const len = parseInt(r.headers.get('Content-Length') || '-1', 10);
					if (r.status === 206) {
						const m = /bytes (\d+)-\d+\/(\d+)/.exec(r.headers.get('Content-Range') || '');
						const start = m ? parseInt(m[1], 10) : got;
						if (start > got) {
							throw new Error('bad range');
						}
						skip = got - start;
						expect = m ? parseInt(m[2], 10) : -1;
					} else if (r.ok) {
						skip = got; // server sent the whole file: drop what we already have
						expect = enc ? -1 : len;
					} else {
						throw new Error('HTTP ' + r.status);
					}
					reader = r.body.getReader();
					return;
				} catch (e) {
					await fail(e);
				}
			}
		}

		return new ReadableStream({
			async pull(controller) {
				for (;;) {
					if (!reader) {
						if (idx >= parts.length) {
							controller.close();
							return;
						}
						await open();
					}
					let res;
					try {
						res = await timeout(reader.read(), STALL_MS, () => ctrl.abort());
					} catch (e) {
						await fail(e);
						continue;
					}
					if (res.done) {
						if (expect > 0 && got < expect) {
							await fail(new Error('truncated'));
							continue;
						}
						reader = null;
						idx++;
						got = 0;
						expect = -1;
						continue;
					}
					let v = res.value;
					fails = 0;
					if (skip > 0) {
						if (v.length <= skip) {
							skip -= v.length;
							continue;
						}
						v = v.subarray(skip);
						skip = 0;
					}
					got += v.length;
					controller.enqueue(v);
					return;
				}
			},
			cancel() {
				try { if (ctrl) { ctrl.abort(); } } catch (e) { /* ignore */ }
			},
		});
	}

	window.fetch = function (input, init) {
		const url = typeof input === 'string' ? input : (input && input.url) || '';
		for (const src of SOURCES) {
			if (src.re.test(url)) {
				return Promise.resolve(new Response(resumableStream(src.parts), { status: 200, headers: { 'Content-Type': src.type } }));
			}
		}
		return nativeFetch(input, init);
	};
})();
