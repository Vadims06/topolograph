# Topolograph

## v2.35.3 (16.10.2023)

### Bug Fix
1. IS-IS with DIS might be missed (all vendors).
2. Nokia IS-IS templates with TE enabled [Issue 42](https://github.com/Vadims06/topolograph/issues/34)
3. Mikrotik OSPF External network templates have been changed

### Enhancements
1. `MAX_EDGE_NUM_TO_SWITCH_TO_SINGLE_SPT_PATH` = **8000** is added to limit the number of ECMP paths. If a graph will be greater than this value, only a single SPT will be shown. ECMP calculation is quite memory consumable for big graphs. If you need ECMP for a big graph - please reach me.
2. Backup paths are not shown as `backup` if they have paths from the shortest paths, i.e. we have four of the shortest paths and we simulate link outage, two out of four SPT link will become unavailable, so next two paths will not be duplicated as `backup` paths.
   Paths with backup paths from SPT
   ![](https://github.com/Vadims06/topolograph/blob/ce9a5babcad55901d1494cb3792022b6817ad6fc/docs/release-notes/v2.35/backup_paths_are_part_of_spt.PNG)
   Backup paths are not part of SPT
   ![](https://github.com/Vadims06/topolograph/blob/ce9a5babcad55901d1494cb3792022b6817ad6fc/docs/release-notes/v2.35/backup_paths_are_not_part_of_spt.PNG)
