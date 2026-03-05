# Contributing

Thanks for considering a contribution.

## Development setup

1. Create a scratch org:
   ```bash
   sfdx force:org:create -f config/project-scratch-def.json -a dtl_dev -s
   sfdx force:source:push
   sfdx force:user:permset:assign -n DTL_Admin
   sfdx force:org:open
   ```

2. Run Apex tests:
   ```bash
   sfdx force:apex:test:run -c -r human
   ```

## Pull requests

- Keep PRs focused and small.
- Add/extend tests for changes.
- Update docs if behavior changes.

## Commit style

- Use concise, imperative subject lines.
- Include context in the body when helpful.

## Reporting bugs

Open an issue with:
- Org type (scratch/sandbox/prod)
- Steps to reproduce
- Expected vs actual behavior
- Any error stack trace / debug log snippet
