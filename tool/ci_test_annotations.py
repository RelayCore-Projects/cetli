"""Failed Flutter tests as GitHub annotations (CI).

Reads the output of `flutter test --file-reporter json:...` and writes one
`::error` line per failed test, so the cause can be read through the GitHub API
without downloading the full log (the log is only available when signed in).
Widget tests report "Test failed. See exception logs above."; in that case the
printed exception log (Expected / Actual / Which) is used instead.
"""
import json
import sys

MAX_MESSAGE = 1500


def escape(text: str) -> str:
    return text.replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')


def escape_property(text: str) -> str:
    return escape(text).replace(':', '%3A').replace(',', '%2C')


def main(path: str) -> None:
    names: dict[int, str] = {}
    urls: dict[int, str] = {}
    errors: dict[int, list[str]] = {}
    prints: dict[int, list[str]] = {}
    failed: list[int] = []
    with open(path, encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line.startswith('{'):
                continue
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            kind = event.get('type')
            if kind == 'testStart':
                test = event['test']
                names[test['id']] = test.get('name', '?')
                url = test.get('root_url') or test.get('url') or ''
                line_no = test.get('root_line') or test.get('line')
                urls[test['id']] = f"{url.rsplit('/', 1)[-1]}:{line_no}" if url else ''
            elif kind == 'print' and 'testID' in event:
                prints.setdefault(event['testID'], []).append(event.get('message', ''))
            elif kind == 'error':
                errors.setdefault(event['testID'], []).append(event.get('error', ''))
            elif kind == 'testDone' and event.get('result') != 'success' and not event.get('hidden'):
                failed.append(event['testID'])
    for test_id in failed:
        error = '\n'.join(errors.get(test_id, []))
        log = '\n'.join(prints.get(test_id, []))
        start = log.find('EXCEPTION CAUGHT')
        if start >= 0:
            error = log[start:] + '\n' + error
        message = error[:MAX_MESSAGE]
        title = f"{names.get(test_id, '?')} ({urls.get(test_id, '')})"
        print(f'::error title={escape_property(title)}::{escape(message)}')
    print(f'{len(failed)} failed test(s).')


if __name__ == '__main__':
    main(sys.argv[1])
