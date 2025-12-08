#!/bin/bash
# infra/scripts/drift-detector.sh
# Advanced drift detection with email notifications

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"
DRIFT_LOG="${SCRIPT_DIR}/../logs/drift-$(date +%Y%m%d-%H%M%S).log"
EMAIL_RECIPIENT="${NOTIFICATION_EMAIL:-jameskefaslungu@gmail.com}"

# Create logs directory
mkdir -p "${SCRIPT_DIR}/../logs"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$DRIFT_LOG"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$DRIFT_LOG" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*" | tee -a "$DRIFT_LOG"
}

send_email_notification() {
    local subject="$1"
    local body="$2"
    local priority="${3:-normal}"
    
    log "Sending email notification..."
    
    # Create HTML email
    cat > /tmp/drift-email.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5; }
        .container { max-width: 700px; margin: 30px auto; background: white; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 8px 8px 0 0; }
        .header.warning { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); }
        .header h1 { margin: 0; font-size: 24px; }
        .content { padding: 30px; }
        .info-box { background: #f8f9fa; border-left: 4px solid #667eea; padding: 15px; margin: 20px 0; border-radius: 4px; }
        .info-box.warning { border-left-color: #f5576c; background: #fff5f5; }
        .info-row { margin: 10px 0; }
        .label { font-weight: 600; color: #495057; display: inline-block; min-width: 120px; }
        .value { color: #212529; }
        .changes { background: #fff3cd; border: 1px solid #ffc107; padding: 15px; border-radius: 4px; margin: 20px 0; }
        .btn { 
            display: inline-block; 
            padding: 12px 24px; 
            background: #667eea; 
            color: white; 
            text-decoration: none; 
            border-radius: 6px; 
            margin: 20px 0;
            font-weight: 600;
        }
        .btn:hover { background: #5568d3; }
        .footer { background: #f8f9fa; padding: 20px; text-align: center; color: #6c757d; border-radius: 0 0 8px 8px; font-size: 14px; }
        code { background: #f8f9fa; padding: 2px 6px; border-radius: 3px; font-family: 'Courier New', monospace; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header ${priority}">
            <h1>🚨 Infrastructure Drift Alert</h1>
            <p style="margin: 10px 0 0 0;">Immediate attention required</p>
        </div>
        <div class="content">
            <div class="info-box warning">
                <strong>⚠️ Drift Detected:</strong> Your infrastructure state has diverged from the Terraform configuration.
            </div>
            
            <div class="info-row">
                <span class="label">Repository:</span>
                <span class="value"><code>${GITHUB_REPOSITORY:-Unknown}</code></span>
            </div>
            <div class="info-row">
                <span class="label">Branch:</span>
                <span class="value"><code>${GITHUB_REF_NAME:-Unknown}</code></span>
            </div>
            <div class="info-row">
                <span class="label">Commit:</span>
                <span class="value"><code>${GITHUB_SHA:-Unknown}</code></span>
            </div>
            <div class="info-row">
                <span class="label">Triggered By:</span>
                <span class="value">${GITHUB_ACTOR:-Manual}</span>
            </div>
            <div class="info-row">
                <span class="label">Time:</span>
                <span class="value">$(date '+%Y-%m-%d %H:%M:%S %Z')</span>
            </div>
            
            <div class="changes">
                <h3 style="margin-top: 0;">📋 Summary</h3>
                <p>${body}</p>
            </div>
            
            <h3>Required Actions:</h3>
            <ol>
                <li>Review the drift details in the GitHub Actions workflow</li>
                <li>Verify if changes are expected or indicate a security issue</li>
                <li>Approve the deployment to apply changes</li>
                <li>Investigate if changes are unexpected</li>
            </ol>
            
            <a href="https://github.com/${GITHUB_REPOSITORY:-}/actions/runs/${GITHUB_RUN_ID:-}" class="btn">
                View Workflow Details →
            </a>
        </div>
        <div class="footer">
            <p>🤖 Automated notification from DevOps Pipeline</p>
            <p><small>Run ID: ${GITHUB_RUN_ID:-N/A} | Workflow: ${GITHUB_WORKFLOW:-Manual}</small></p>
        </div>
    </div>
</body>
</html>
EOF

    # Send using mail command if available
    if command -v mail &> /dev/null; then
        cat /tmp/drift-email.html | mail -s "$(echo -e "$subject\nContent-Type: text/html")" "$EMAIL_RECIPIENT"
    elif command -v sendmail &> /dev/null; then
        {
            echo "To: $EMAIL_RECIPIENT"
            echo "Subject: $subject"
            echo "Content-Type: text/html"
            echo ""
            cat /tmp/drift-email.html
        } | sendmail -t
    else
        warning "No mail command available. Email notification skipped."
        log "Email body saved to: /tmp/drift-email.html"
    fi
    
    rm -f /tmp/drift-email.html
}

check_terraform_drift() {
    log "Checking for infrastructure drift..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    log "Initializing Terraform..."
    terraform init -input=false
    
    # Run terraform plan with detailed exit code
    log "Running terraform plan..."
    set +e
    terraform plan -detailed-exitcode -out=tfplan 2>&1 | tee -a "$DRIFT_LOG"
    PLAN_EXIT_CODE=${PIPESTATUS[0]}
    set -e
    
    case $PLAN_EXIT_CODE in
        0)
            log "✅ No drift detected - Infrastructure is in sync"
            return 0
            ;;
        1)
            error "Terraform plan failed with errors"
            return 1
            ;;
        2)
            warning "⚠️  DRIFT DETECTED - Infrastructure changes are required"
            
            # Extract summary from plan
            CHANGES_SUMMARY=$(terraform show -no-color tfplan 2>&1 | grep -A 20 "Terraform will perform" || echo "Changes detected")
            
            # Send notification
            send_email_notification \
                "⚠️ Infrastructure Drift Detected - Action Required" \
                "$CHANGES_SUMMARY" \
                "warning"
            
            return 2
            ;;
        *)
            error "Unexpected exit code from terraform plan: $PLAN_EXIT_CODE"
            return 1
            ;;
    esac
}

wait_for_approval() {
    log "Waiting for manual approval..."
    warning "Deployment paused pending approval"
    
    if [ -n "${CI:-}" ]; then
        log "Running in CI environment - approval handled by CI system"
        return 0
    fi
    
    echo -e "\n${YELLOW}Drift detected. Changes will be applied to infrastructure.${NC}"
    echo -e "${YELLOW}Review the plan above carefully.${NC}\n"
    
    read -p "Do you want to apply these changes? (yes/no): " -r
    echo
    
    if [[ $REPLY =~ ^[Yy]es$ ]]; then
        log "✅ Manual approval received"
        return 0
    else
        error "❌ Deployment cancelled by user"
        return 1
    fi
}

apply_terraform() {
    log "Applying Terraform changes..."
    
    cd "$TERRAFORM_DIR"
    
    if [ -f tfplan ]; then
        terraform apply tfplan
    else
        terraform apply -auto-approve
    fi
    
    log "✅ Terraform apply completed successfully"
}

main() {
    log "=== Drift Detection Pipeline Started ==="
    log "Terraform directory: $TERRAFORM_DIR"
    log "Log file: $DRIFT_LOG"
    
    # Check for drift
    if check_terraform_drift; then
        log "No changes required - exiting"
        exit 0
    fi
    
    DRIFT_CODE=$?
    
    if [ $DRIFT_CODE -eq 2 ]; then
        # Drift detected - wait for approval
        if wait_for_approval; then
            apply_terraform
            log "=== Drift Detection Pipeline Completed Successfully ==="
            exit 0
        else
            error "=== Drift Detection Pipeline Cancelled ==="
            exit 1
        fi
    else
        # Error occurred
        error "=== Drift Detection Pipeline Failed ==="
        exit 1
    fi
}

# Run main function
main "$@"