
#!/bin/bash
set -e

# Build the site
./start_jekyll.sh build

# Exit after build is complete
echo "Daily build completed"
exit 0
