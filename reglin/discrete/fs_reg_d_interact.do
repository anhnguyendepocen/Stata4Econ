cls
clear
macro drop _all

/*
  Back to Fan's Stata4Econ or other repositories:
  - http://fanwangecon.github.io
  - http://fanwangecon.github.io/Stata4Econ
  - http://fanwangecon.github.io/R4Econ
  - http://fanwangecon.github.io/M4Econ
  - http://fanwangecon.github.io/CodeDynaAsset/
  - http://fanwangecon.github.io/Math4Econ/
  - http://fanwangecon.github.io/Stat4Econ/
  - http://fanwangecon.github.io/Tex4Econ

  1. Same regression for two Subgroups
  2. Show alll subgroup coefficients in one regression
*/

///--- Start log
set more off
capture log close
cd "${root_log}"
global curlogfile "~\Stata4Econ\reglin\discrete\fs_reg_d_interact"
log using "${curlogfile}" , replace
log on

///--- Load Data
set more off
sysuse auto, clear

tab rep78
tab foreign

* 1. Same regression for two Subgroups
eststo clear
eststo, title(dom): regress weight ib3.rep78 if foreign == 0
eststo, title(foreign): regress weight ib3.rep78 if foreign == 1
esttab, mtitle title("Foreign or Domestic")

* 2. Show alll subgroup coefficients in one regression
capture drop domestic
recode foreign ///
   (0 = 1 "domestic") ///1
   (1 = 0 "foreign") ///
   (else = .) ///
   , ///
   gen(domestic)
tab domestic foreign

* using factor for binary
eststo clear
eststo, title(both): quietly regress ///
    weight ///
    ib0.foreign ib0.domestic ///
    ib3.rep78#ib0.foreign ///
    ib3.rep78#ib0.domestic ///
    , noc
esttab, mtitle title("Foreign or Domestic")

* Streamlined
eststo clear
regress ///
    weight ///
    ib0.foreign ib0.domestic ///
    ib3.rep78#ib0.foreign ///
    , noc
esttab, mtitle title("Foreign or Domestic")

* Streamlined 2
eststo clear
regress ///
    weight ///
    ib0.foreign ///
    ib3.rep78#ib0.foreign
esttab, mtitle title("Foreign or Domestic")

* using cts for binary
eststo clear
eststo, title(both): quietly regress ///
    weight ///
    c.foreign c.domestic ///
    ib3.rep78#c.foreign ///
    ib3.rep78#c.domestic ///
    , noc
esttab, mtitle title("Foreign or Domestic")

///--- End Log and to HTML
log close
capture noisily {
  log2html "${curlogfile}", replace
}
///--- to PDF
capture noisily {
	translator set Results2pdf logo off
	translator set Results2pdf fontsize 8
	translator set Results2pdf pagesize custom
	translator set Results2pdf pagewidth 9
	translator set Results2pdf pageheight 20
	translator set Results2pdf lmargin 0.2
	translator set Results2pdf rmargin 0.2
	translator set Results2pdf tmargin 0.2
	translator set Results2pdf bmargin 0.2
	translate @Results "${curlogfile}.pdf", replace translator(Results2pdf)
}
capture noisily {
  erase "${curlogfile}.smcl"
}
