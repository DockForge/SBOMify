# [SBOMify](https://github.com/DockForge/SBOMify)

SBOMify is a GitHub Action to capture and list installed packages and their versions in a Docker image, generating Software Bill of Materials (SBOM) files. This action leverages some special technics to scan Docker images and output SBOM files in both table and JSON formats.

## Features

- Scan multiple Docker images for installed packages and versions
- Generate SBOM files in both human-readable table format and machine-readable JSON format
- Customize the output file names and paths
- Automatically commit and push SBOM files to the repository

## Usage

### Inputs

- `images` (required): Comma-separated list of Docker images to scan.
- `github_token` (required): GitHub token for authentication.
- `output_path` (optional): Path to store the SBOM files. Default is the root of the repository.
- `sbom_file_prefix` (optional): Prefix for the SBOM files. Default is an empty string.
- `sbom_file_suffix` (optional): Suffix for the SBOM files. Default is an empty string.
- `sbom_file_name` (optional): Name template for the SBOM files. Default is `[REPOSITORY]_[TAG]`.

### Example Workflow

Here's an example of how to use the SBOMify action in a GitHub workflow:

```yaml
name: Generate SBOM
on:
  push:
    branches:
      - main

jobs:
  sbom:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4.1.6

      - name: Run SBOMify
        uses: DockForge/SBOMify@v1
        with:
          images: 'ubuntu:20.04,alpine:latest'
          github_token: ${{ secrets.GITHUB_TOKEN }}
          output_path: 'sbom'
          sbom_file_prefix: 'sbom_'
          sbom_file_suffix: '_scan'
          sbom_file_name: '[REPOSITORY]_[TAG]'
```

### Outputs

SBOMify generates the following files for each Docker image:

- `[output_path]/[sbom_file_prefix][REPOSITORY]_[TAG][sbom_file_suffix].txt`: Human-readable table format
- `[output_path]/[sbom_file_prefix][REPOSITORY]_[TAG][sbom_file_suffix].json`: JSON format

### Customization

You can customize the file names and paths using the `output_path`, `sbom_file_prefix`, `sbom_file_suffix`, and `sbom_file_name` inputs. The default `sbom_file_name` template is `[REPOSITORY]_[TAG]`, where `[REPOSITORY]` is replaced with the repository name and `[TAG]` is replaced with the image tag.

### Example

For an image `ubuntu:20.04` with the default settings, SBOMify will generate the following files:

- `sbom/sbom_ubuntu_20.04_scan.txt`
- `sbom/sbom_ubuntu_20.04_scan.json`

## License

This project is licensed under the GNU GENERAL PUBLIC LICENSE. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Contact

For any inquiries, please contact us at [dockforge@gmail.com](mailto:dockforge@gmail.com).
