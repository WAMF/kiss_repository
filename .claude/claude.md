# Claude AI Assistant Guidelines

This document contains important guidelines for AI assistants working on this codebase.

## Code Quality Standards

### Linting and Analysis Rules

**IMPORTANT: Do not disable linting rules or analysis options unless explicitly requested by the user.**

- Always fix linting issues properly rather than disabling the rules
- Maintain code quality by addressing warnings and info messages
- Only use `// ignore:` comments when specifically requested
- Do not modify `analysis_options.yaml` to disable rules unless the user explicitly asks for it

### Best Practices

- Fix issues at their source rather than suppressing warnings
- Maintain consistent formatting using `dart format`
- Address type safety issues properly with explicit casting
- Keep dependencies sorted alphabetically in `pubspec.yaml`
- Add proper documentation for public APIs
- Use `dart fix --apply` for automatic fixes when available

## Exception

The only pre-approved linting rule disable in this project is:
- `public_member_api_docs: false` for the example app (since it's demonstration code)

All other linting rules should remain enabled and issues should be fixed properly. 
