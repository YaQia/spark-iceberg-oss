# Contributing to Spark + Iceberg + OSS

First off, thank you for considering contributing to this project! 🎉

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples**
- **Describe the behavior you observed and what you expected**
- **Include logs and error messages**
- **Specify your environment** (OS, Docker version, etc.)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description of the suggested enhancement**
- **Explain why this enhancement would be useful**
- **List any alternatives you've considered**

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following the coding standards
3. **Test your changes** thoroughly
4. **Update documentation** if needed
5. **Write clear commit messages**
6. **Submit a pull request**

## Development Setup

### Prerequisites

- Docker 20.10+
- Docker Compose 1.29+
- Git

### Setup Steps

1. Clone your fork:
```bash
git clone https://github.com/your-username/spark-iceberg-oss.git
cd spark-iceberg-oss
```

2. Configure OSS credentials:
```bash
cp .env.template .env
# Edit .env with your credentials
```

3. Build and test:
```bash
make build
make up
make example
```

## Coding Standards

### Dockerfile

- Use official base images
- Pin versions explicitly
- Add comments for complex commands
- Minimize layer count
- Clean up in the same layer

### Python (PySpark)

- Follow PEP 8 style guide
- Use docstrings for functions and classes
- Add type hints where appropriate
- Keep functions focused and small

### SQL

- Use uppercase for SQL keywords
- Indent nested queries
- Add comments for complex logic
- Use meaningful table and column names

### Shell Scripts

- Use `#!/bin/bash` shebang
- Use `set -e` for error handling
- Add comments for complex logic
- Make scripts executable

## Documentation

- Update README when adding features
- Add examples for new functionality
- Keep documentation in sync with code
- Use clear and concise language

## Commit Messages

Format:
```
<type>: <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

Example:
```
feat: Add support for Iceberg branching

Implemented support for Iceberg table branching feature.
This allows users to create and manage branches of their tables.

Closes #123
```

## Testing

Before submitting:

1. Build the Docker image successfully
2. Start the cluster without errors
3. Run example scripts successfully
4. Test with your OSS bucket
5. Verify documentation is accurate

## Questions?

Feel free to:
- Open an issue for discussion
- Ask in pull request comments
- Check existing documentation

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Accept constructive criticism
- Focus on what's best for the community

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.

---

Thank you for contributing! 🙏
