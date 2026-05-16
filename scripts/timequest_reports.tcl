# Extra TimeQuest path reports for modernization work.
#
# This script is run by Quartus through TIMEQUEST_REPORT_SCRIPT after the
# default timing analysis. Do not open or close the project here.

set report_dir "output_files/timing_paths"
file mkdir $report_dir

proc cave_write_timing_report {panel analysis file_name} {
  set result [catch {
    report_timing $analysis \
      -npaths 20 \
      -nworst 1 \
      -detail full_path \
      -panel_name $panel \
      -file $file_name
  } message]

  if {$result != 0} {
    post_message -type warning "Could not write $panel timing report: $message"
  }
}

cave_write_timing_report "Modernization Setup Paths" -setup "$report_dir/setup_paths.rpt"
cave_write_timing_report "Modernization Hold Paths" -hold "$report_dir/hold_paths.rpt"
cave_write_timing_report "Modernization Recovery Paths" -recovery "$report_dir/recovery_paths.rpt"
