* driveuse_example.do: common uses of driveuse. Paths are inside the
* Data and Research Team shared drive unless drive() names another.

* find the drive and set $sf and $driveuse
driveuse

* load a dataset, all of it or part of it
driveuse "project/data/survey.dta", clear
driveuse "project/data/survey.dta" if year == 2024, clear
driveuse id age income using "project/data/survey.dta", clear
driveuse using "project/data/survey.dta" in 1/100, clear

* save output next to it with the global
save "$sf/project/output/survey_clean.dta", replace

* work in another shared drive
driveuse "project/file.dta", drive("Other Drive") clear
