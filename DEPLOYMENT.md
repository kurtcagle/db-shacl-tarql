# Deployment Instructions

## For GitHub

1. **Initialize Git repository**:
   ```bash
   cd hr-database-rdf
   git init
   git add .
   git commit -m "Initial commit: HR Database to RDF transformation pipeline"
   ```

2. **Create GitHub repository**:
   - Go to https://github.com/new
   - Name: `hr-database-rdf`
   - Description: "Transform SQL Server HR database to RDF knowledge graph with SHACL 1.2 validation"
   - Public or Private (your choice)
   - Do NOT initialize with README, .gitignore, or license (we have them)

3. **Push to GitHub**:
   ```bash
   git remote add origin https://github.com/yourusername/hr-database-rdf.git
   git branch -M main
   git push -u origin main
   ```

4. **Add topics** (on GitHub repository page):
   - `semantic-web`
   - `rdf`
   - `shacl`
   - `tarql`
   - `knowledge-graph`
   - `linked-data`
   - `sparql`
   - `ontology`

5. **Enable GitHub Pages** (optional, for documentation):
   - Settings → Pages
   - Source: Deploy from branch `main`
   - Folder: `/docs`

## Post-Deployment Checklist

- [ ] Verify all files are present
- [ ] Check README.md renders correctly with Mermaid diagrams
- [ ] Test quick start instructions
- [ ] Add repository description
- [ ] Add topics/tags
- [ ] Create first release (v1.0.0)
- [ ] Share on social media
- [ ] Post article to Substack

## Creating a Release

```bash
git tag -a v1.0.0 -m "Initial release: Complete HR-to-RDF pipeline"
git push origin v1.0.0
```

Then create release on GitHub:
- Go to Releases → Draft a new release
- Choose tag: v1.0.0
- Title: "v1.0.0 - Initial Release"
- Description: Copy from CHANGELOG.md
- Attach compiled/packaged artifacts if needed
- Publish release

## Repository Settings Recommendations

**General**:
- Features: Issues ✓, Wikis ✗, Discussions (optional)
- Pull Requests: Allow squash merging ✓

**Branches**:
- Default branch: `main`
- Branch protection: Require PR reviews for main

**Actions** (if using CI/CD):
- Enable GitHub Actions
- Add workflow for SHACL validation

## File Structure Verification

After deployment, verify this structure exists:

```
hr-database-rdf/
├── README.md                  ✓
├── LICENSE                    ✓
├── .gitignore                 ✓
├── CHANGELOG.md              ✓
├── CONTRIBUTING.md           ✓
├── sql/
│   ├── hr_database.sql       ✓
│   ├── sp_GetEmployeeList.sql ✓
│   └── sql_export_strategy.sql ✓
├── shacl/
│   └── hr_database_shacl.ttl ✓
├── tarql/
│   ├── tarql_*.sparql        ✓ (9 files)
│   └── run_tarql_transformations.sh ✓
├── test-data/
│   ├── *.csv                 ✓ (11 files)
│   ├── README.md             ✓
│   └── TEST_DATA_SUMMARY.md  ✓
├── output/
│   ├── .gitkeep              ✓
│   ├── README.md             ✓
│   ├── positions_output.ttl  ✓
│   └── employees_output.ttl  ✓
└── docs/
    ├── TARQL_README.md       ✓
    ├── TARQL_PACKAGE_SUMMARY.md ✓
    ├── TRANSFORMATION_RESULTS.md ✓
    ├── SHACL_VALIDATION_REPORT.md ✓
    └── SUBSTACK_ARTICLE.md   ✓
```

## Troubleshooting

**Problem**: Mermaid diagrams don't render on GitHub
- Solution: GitHub supports Mermaid natively in markdown
- Verify syntax is correct (no extra spaces)
- Check GitHub's Mermaid documentation

**Problem**: Files missing after push
- Solution: Check .gitignore isn't excluding them
- Use `git status` to see untracked files
- Use `git add -f` to force-add if needed

**Problem**: Line endings issue (Windows)
- Solution: Configure git to handle CRLF
  ```bash
  git config core.autocrlf true
  ```

## Support

Questions? Open an issue or contact:
- Email: kurt.cagle@gmail.com
- LinkedIn: linkedin.com/in/kurtcagle
