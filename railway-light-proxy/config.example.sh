# Copy to config.sh. Do not commit config.sh.
# deploy.sh, check.sh, test-tcp-proxy.sh and fix-profile.sh read PROXY_CONFIG or config.sh.
PROXY_USER=''
PROXY_PASS=''
# Host and port assigned by your deployment, for example proxy.example.org:443.
PROXY_HOST=''
# Export these when using the GraphQL or environment patch scripts.
export RAILWAY_SERVICE_ID=''
export RAILWAY_ENVIRONMENT_ID=''
# Optional token override. Otherwise the scripts use the Railway CLI login.
export RAILWAY_TOKEN=''
# grep-railway.sh requires a local directory of Railway reference files.
export RAILWAY_REFERENCE_DIR=''
