# /test — Run full test suite

Run the full test suite for all relevant parts of the project and report results clearly.

## Steps

1. **Go backend** — run in `backend-go/`:
   ```
   go test ./... 2>&1
   ```
   Report pass/fail per package. Show error details on failure.

2. **Frontend build** — run in `frontend/`:
   ```
   npm run build 2>&1
   ```
   This executes `tsc` (type check) + `vite build`. Show errors if any.

3. **Summary** — list which checks passed and which failed. If anything failed, fix it before reporting done.

## Notes
- Skip a step if its directory does not exist or deps are not installed.
- For Go: `go build ./...` is a quick syntax/compile check; `go test ./...` runs unit tests.
- For frontend: `npm run build` is the full check; `node_modules/.bin/tsc --noEmit` is type-check only.
