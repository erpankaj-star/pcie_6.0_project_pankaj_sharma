# Load and merge your run database
merge ./cov_work/scope/test -out ./cov_work/merged_db -overwrite

# Load the merged database
load -run ./cov_work/merged_db

# Generate HTML report (Correct syntax for IMC TCL)
report_metrics -out cov_html_report -detail -metrics block:expr:toggle:fsm:functional

# Exit IMC
exit

