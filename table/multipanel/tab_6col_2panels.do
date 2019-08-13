cls
clear

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

	Regression Table where:
  - shared regression outcome lhs variable
  - for each panel, rhs variables differ
	- for each column, conditioning differs, but rhs vars the same
*/

///--- Start log
capture log close
cd "${root_log}"
global curlogfile "~\Stata4Econ\table\multipanel\tab_6col_2panels"
log using "${curlogfile}_log" , replace
log on

set trace off
set tracedepth 1

/////////////////////////////////////////////////
///--- Load Data
/////////////////////////////////////////////////

set more off
sysuse auto, clear
tab rep78
tab foreign

/////////////////////////////////////////////////
///--- A1. Define Regression Variables
/////////////////////////////////////////////////

	* shared regression outcome lhs variable
	global svr_outcome "price"

	* for each panel, rhs variables differ
	global svr_rhs_panel_a "mpg ib1.rep78 displacement gear_ratio"
	global svr_rhs_panel_b "headroom mpg trunk weight displacement gear_ratio"
	global svr_rhs_panel_c "headroom turn length weight trunk"

	* for each column, conditioning differs
	global it_reg_n = 6
	global sif_col_1 "weight <= 4700"
	global sif_col_2 "weight <= 4500"
	global sif_col_3 "weight <= 4300"
	global sif_col_4 "weight <= 4100"
	global sif_col_5 "weight <= 3900"
	global sif_col_6 "weight <= 3700"

	* esttad strings for conditioning what were included
	scalar it_esttad_n = 4
	matrix mt_bl_estd = J(it_esttad_n, $it_reg_n, 0)
	matrix rownames mt_bl_estd = incdgr4500 incdgr4000 incdgr3500 incdgr3000
	matrix colnames mt_bl_estd = reg1 reg2 reg3 reg4 reg5 reg6
	matrix mt_bl_estd[1, 1] = (1\1\1\1)
	matrix mt_bl_estd[1, 2] = (1\1\1\1)
	matrix mt_bl_estd[1, 3] = (0\1\1\1)
	matrix mt_bl_estd[1, 4] = (0\1\1\1)
	matrix mt_bl_estd[1, 5] = (0\0\1\1)
	matrix mt_bl_estd[1, 6] = (0\0\1\1)
	global st_estd_rownames : rownames mt_bl_estd
	global slb_estd_1 "the weight <= 4700"
	global slb_estd_2 "the weight <= 4500"
	global slb_estd_3 "the weight <= 4300"
	global slb_estd_4 "the weight <= 4100"

/////////////////////////////////////////////////
///--- A2. Define Regression Technical Strings
/////////////////////////////////////////////////

///--- Technical Controls
	global stc_regc "regress"
	global stc_opts ", noc"

/////////////////////////////////////////////////
///--- B1. Define Regressions Panel A
/////////////////////////////////////////////////

	/*
		di "$srg_panel_a_col_1"
		di "$srg_panel_a_col_2"
		di "$srg_panel_a_col_6"
	*/
	foreach it_regre of numlist 1(1)$it_reg_n {
		#delimit;
		global srg_panel_a_col_`it_regre' "
		  $stc_regc $svr_outcome $svr_rhs_panel_a if ${sif_col_`it_regre'} $stc_opts
		  ";
		#delimit cr
		di "${srg_panel_a_col_`it_regre'}"
	}

/////////////////////////////////////////////////
///--- B2. Define Regressions Panel B
/////////////////////////////////////////////////

	/*
		di "$srg_panel_b_col_1"
		di "$srg_panel_b_col_2"
		di "$srg_panel_b_col_6"
	*/
	foreach it_regre of numlist 1(1)$it_reg_n {
		#delimit;
		global srg_panel_b_col_`it_regre' "
		  $stc_regc $svr_outcome $svr_rhs_panel_b if ${sif_col_`it_regre'} $stc_opts
		  ";
		#delimit cr
		di "${srg_panel_b_col_`it_regre'}"
	}

/////////////////////////////////////////////////
///--- B3. Define Regressions Panel C
/////////////////////////////////////////////////

	/*
		di "$srg_panel_c_col_1"
		di "$srg_panel_c_col_2"
		di "$srg_panel_c_col_6"
	*/

	foreach it_regre of numlist 1(1)$it_reg_n {
		#delimit;
		global srg_panel_c_col_`it_regre' "
		  $stc_regc $svr_outcome $svr_rhs_panel_c if ${sif_col_`it_regre'} $stc_opts
		  ";
		#delimit cr
		di "${srg_panel_c_col_`it_regre'}"
	}

/////////////////////////////////////////////////
///--- C. Run Regressions
/////////////////////////////////////////////////

	eststo clear
	local it_reg_ctr = 0
	foreach st_panel in panel_a panel_b panel_c {

	  global st_cur_sm_stor "smd_`st_panel'_m"
	  global ${st_cur_sm_stor} ""

	  foreach it_regre of numlist 1(1)$it_reg_n {

		  local it_reg_ctr = `it_reg_ctr' + 1
		  global st_cur_srg_name "srg_`st_panel'_col_`it_regre'"

		  di "st_panel:`st_panel', it_reg_ctr:`it_reg_ctr', st_cur_srg_name:${st_cur_srg_name}"

		  ///--- Regression
		  eststo m`it_reg_ctr', title("${sif_col_`it_regre'}") : ${$st_cur_srg_name}

		  ///--- Estadd Controls
			foreach st_estd_name in $st_estd_rownames {
				scalar bl_estad = el(mt_bl_estd, rownumb(mt_bl_estd, "`st_estd_name'"), `it_regre')
				if (bl_estad) {
					estadd local `st_estd_name' "Yes"
				}
				else {
					estadd local `st_estd_name' "No"
				}
			}

		  ///--- Track Regression Store
		  global $st_cur_sm_stor "${${st_cur_sm_stor}} m`it_reg_ctr'"
	  }

	  di "${${st_cur_sm_stor}}"

	}


	di "$smd_panel_a_m"
	di "$smd_panel_b_m"
	di "$smd_panel_c_m"

/////////////////////////////////////////////////
///--- D1. Labeling
/////////////////////////////////////////////////

///--- Title overall
	global slb_title "Outcome: Attending School or Not"
	global slb_panel_a "Group A: Coefficients for Distance to Elementary School Variables"
	global slb_panel_b "Group B: Coefficients for Elementary School Physical Quality Variables"
	global slb_panel_c "Group C: More Coefficientss"
	global slb_bottom "Controls for each panel:"
	global slb_note "${slb_starLvl}. Standard Errors clustered at village level. Each Column is a spearate regression."

///--- Show which coefficients to keep
	#delimit;
	global svr_coef_keep_panel_a "
	  mpg
	  2.rep78 3.rep78
	  4.rep78 5.rep78
	  ";
	global svr_coef_keep_panel_b "
	  headroom
	  mpg
	  trunk
	  weight
	  ";
	global svr_coef_keep_panel_c "
	  turn
	  ";
	#delimit cr

///--- Labeling for for Coefficients to Show
	#delimit;
	global svr_starts_var_panel_a "mpg";
	global slb_coef_label_panel_a "
	  mpg "miles per gallon"
	  2.rep78 "rep78 is 2"
	  3.rep78 "rep78 is 3"
	  4.rep78 "rep78 is 4"
	  5.rep78 "rep78 is 5"
	  ";
	#delimit cr

	#delimit;
	global svr_starts_var_panel_b "headroom";
	global slb_coef_label_panel_b "
	  headroom "headroom variable"
	  mpg "miles per gallon"
	  trunk "this is the trunk variable"
	  weight "and here the weight variable"
	  ";
	#delimit cr

	#delimit;
	global svr_starts_var_panel_c "turn";
	global slb_coef_label_panel_c "
	  turn "variable is turn"
	  ";
	#delimit cr

/////////////////////////////////////////////////
///--- D2. Regression Display Controls
/////////////////////////////////////////////////

	global slb_reg_stats "N ${st_estd_rownames}"

	global slb_starLvl "* 0.10 ** 0.05 *** 0.01"
	global slb_starComm "nostar"

	global slb_sd_tex `"se(fmt(a2) par("\vspace*{-2mm}{\footnotesize (" ") }"))"'
	global slb_cells_tex `"cells(b(star fmt(a2)) $slb_sd_tex)"'
	global slb_esttab_opt_tex "booktabs label collabels(none) nomtitles nonumbers star(${slb_starLvl})"

	global slb_sd_txt `"se(fmt(a2) par("(" ")"))"'
	global slb_cells_txt `"cells(b(star fmt(a2)) $slb_sd_txt)"'
	global slb_esttab_opt_txt "stats(${slb_reg_stats}) collabels(none) mtitle nonumbers varwidth(30) modelwidth(15) star(${slb_starLvl}) addnotes(${slb_note})"

	#delimit ;
	global slb_panel_a_main "
		title("${slb_panel_a}")
		keep(${svr_coef_keep_panel_a}) order(${svr_coef_keep_panel_a})
		coeflabels($slb_coef_label_panel_a)
		";

	global slb_panel_b_main "
		title("${slb_panel_b}")
		keep(${svr_coef_keep_panel_b}) order(${svr_coef_keep_panel_b})
		coeflabels($slb_coef_label_panel_b)
		";

	global slb_panel_c_main "
		title("${slb_panel_c}")
		keep(${svr_coef_keep_panel_c}) order(${svr_coef_keep_panel_c})
		coeflabels($slb_coef_label_panel_c)
		";
	#delimit cr

/////////////////////////////////////////////////
///--- E. Regression Shows
/////////////////////////////////////////////////

	esttab ${smd_panel_a_m}, ${slb_panel_a_main} ${slb_esttab_opt_txt}
	esttab ${smd_panel_b_m}, ${slb_panel_b_main} ${slb_esttab_opt_txt}
	esttab ${smd_panel_c_m}, ${slb_panel_c_main} ${slb_esttab_opt_txt}

/////////////////////////////////////////////////
///--- F1. Define Latex Column Groups and Column Sub-Groups
/////////////////////////////////////////////////

	///--- Column Groups
	global it_max_col = 8
	global it_min_col = 2
	global colSeq "2 4 6 8"

	///--- Group 1, columns 1 and 2
	global labG1 "All Age 5 to 12"
	global labC1 "{\small All Villages}"
	global labC2 "{\small No Teachng Points}"

	///--- Group 2, columns 3 and 4
	global labG2 "Girls Age 5 to 12"
	global labC3 "{\small All Villages}"
	global labC4 "{\small No Teachng Points}"

	///--- Group 3, columns 5 and 6
	global labG3 "Boys Age 5 to 12"
	global labC5 "{\small All Villages}"
	global labC6 "{\small No Teachng Points}"

	///--- Column Widths
	global perCoefColWid = 1.85
	global labColWid = 6.75

	///--- Column Fractional Adjustment, 1 = 100%
	global tableAdjustBoxWidth = 1.0

/////////////////////////////////////////////////
///--- F2. Tabling Calculations
/////////////////////////////////////////////////

	///--- Width Calculation
	global totCoefColWid = ${perCoefColWid}*${totCoefColCnt}
	global totColCnt = $totCoefColCnt + 1
	global totColWid = ${labColWid} + ${totCoefColWid} + ${perCoefColWid}
	global totColWidFootnote = ${labColWid} + ${totCoefColWid} + ${perCoefColWid} + ${perCoefColWid}/2
	global totColWidLegend = ${labColWid} + ${totCoefColWid} + ${perCoefColWid}
	global totColWidLegendthin = ${totCoefColWid} + ${perCoefColWid}

	di "totCoefColCnt:$totCoefColCnt"
	di "totCoefColWid:$totCoefColWid"
	di "totCoefColWid:$totCoefColWid"
	di "totCoefColWid:$totCoefColWid"
	di "totCoefColWid:$totCoefColWid"
	di "totCoefColWid:$totCoefColWid"

	global ampersand ""
	foreach curLoop of numlist 1(1)$totCoefColCnt {
	  global ampersand "$ampersand &"
	}
	di "ampersand:$ampersand"

	global alignCenter "m{${labColWid}cm}"
	local eB1 ">{\centering\arraybackslash}m{${perCoefColWid}cm}"
	foreach curLoop of numlist 1(1)$totCoefColCnt {
	  global alignCenter "$alignCenter `eB1'"
	}
	di "alignCenter:$alignCenter"

/////////////////////////////////////////////////
///--- G1. Tex Sectioning
/////////////////////////////////////////////////

	global rcSpaceInit "\vspace*{-5mm}\hspace*{-3mm}"

	#delimit ;
	global slb_titling_panel_a "
		${svr_starts_var_panel_a} "\multicolumn{$totColCnt}{L{${totColWidLegend}cm}}{${rcSpaceInit}\textbf{${slb_panel_a}}} \\"
		";
	global slb_refcat_panel_a `"refcat(${slb_titling_panel_a}, nolabel)"';
	#delimit cr

	#delimit ;
	global slb_titling_panel_b "
		${svr_starts_var_panel_b} "\multicolumn{$totColCnt}{L{${totColWidLegend}cm}}{${rcSpaceInit}\textbf{${slb_panel_b}}} \\"
		";
	global slb_refcat_panel_b `"refcat(${slb_titling_panel_b}, nolabel)"';
	#delimit cr

	#delimit ;
	global slb_titling_panel_c "
		${svr_starts_var_panel_c} "\multicolumn{$totColCnt}{L{${totColWidLegend}cm}}{${rcSpaceInit}\textbf{${slb_panel_c}}} \\"
		";
	global slb_refcat_panel_c `"refcat(${slb_titling_panel_c}, nolabel)"';
	#delimit cr

	#delimit ;
	global slb_titling_bottom `"
	stats(N $st_estd_rownames,
			labels(Observations
			"\midrule \multicolumn{${totColCnt}}{L{${totColWid}cm}}{\vspace*{-5mm}\hspace*{0.0mm}\textbf{\textit{\normalsize ${slb_bottom}}}} \\ $ampersand \\ ${slb_estd_1}"
			"${slb_estd_2}"
			"${slb_estd_3}"
			"${slb_estd_4}"))"';
	#delimit cr

/////////////////////////////////////////////////
///--- G2. Tex Headline
/////////////////////////////////////////////////

	///--- C.3.A. Initialize
	global row1 "&"
	global row1MidLine ""
	global row2 ""
	global row2MidLine ""
	global row3 ""

	///--- B. Row 2 and row 2 midline
	* global colSeq "2 3 6"
	global cmidrule ""
	global colCtr = -1
	foreach curCol of numlist $colSeq {

		global colCtr = $colCtr + 1
		global curCol1Min = `curCol' - 1
		if ($colCtr == 0 ) {
			global minCoefCol = "`curCol'"
		}
		if ($colCtr != 0 ) {
			global gapCnt = (`curCol' - `lastCol')
			global gapWidth = (`curCol' - `lastCol')*$perCoefColWid
			di "curCol1Min:$curCol1Min, lastCol:`lastCol'"
			di "$gapCnt"

			di "\multicolumn{$gapCnt}{C{${gapWidth}cm}}{\small no Control}"
			di "\cmidrule(l{5pt}r{5pt}){`lastCol'-$curCol1Min}"

			global curRow2MidLine "\cmidrule(l{5pt}r{5pt}){`lastCol'-$curCol1Min}"
			global row2MidLine "$row2MidLine $curRow2MidLine"

			global curRow2 "\multicolumn{$gapCnt}{C{${gapWidth}cm}}{\small ${labG${colCtr}}}"
			global row2 "$row2 & $curRow2"

		}
		local lastCol = `curCol'

	}

	///--- C. Row 3
	* Initial & for label column
	foreach curLoop of numlist 1(1)$totCoefColCnt {
		global curText "${labC`curLoop'}"
		global textUse "(`curLoop')"
		if ("$curText" != "") {
			global textUse "$curText"
		}
		global curRow3 "\multicolumn{1}{C{${perCoefColWid}cm}}{$textUse}"
		global row3 "$row3 & $curRow3"
	}

	///--- D. Row 1 and midline:
	global row1 "${row1} \multicolumn{${totCoefColCnt}}{C{${totCoefColWid}cm}}{${allCoefRowHeading}}"
	global row1MidLine "\cmidrule(l{5pt}r{5pt}){${minCoefCol}-${curCol1Min}}"

	///--- C.3.E Print lines
	di "$row1 \\"
	di "$row1MidLine "
	di "$row2 \\"
	di "$row2MidLine"
	di "$row3 \\"

	///--- C.4 Together
	#delimit ;

	local fileTitle "${MainCaption}";
	local tableLabelName "${labelName}";

	///--- 1. Section
	* local section "
		* \section{`fileTitle'}\vspace*{-6mm}
		* ";

	///--- 2. Align and Column Define
	local centering "$alignCenter";

	global headline "
			$row1 \\
			$row1MidLine
			$row2 \\
			$row2MidLine
			$row3 \\
		";

	#delimit cr

/////////////////////////////////////////////////
///--- G4. Head
/////////////////////////////////////////////////

	#delimit ;

	global adjustBoxStart "\begin{adjustbox}{max width=${tableAdjustBoxWidth}\textwidth}";
	global adjustBoxEnd "\end{adjustbox}";

	global notewrap "
			\addlinespace[-0.5em]
			\multicolumn{${totColCnt}}{L{${totColWidFootnote}cm}}{
				\footnotesize
				\justify
				$notelong} \\
		";

	global startTable "\begin{table}[htbp]
			\centering
			\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}
			\caption{`fileTitle'\label{`tableLabelName'}}
			${adjustBoxStart}
			\begin{tabular}{`centering'}
			\toprule
			";

	global headlineAll "prehead(${startTable}${headline})";
	global headlineAllNoHead "prehead(${startTable})";
	global postAll "postfoot(\bottomrule ${notewrap} \end{tabular}${adjustBoxEnd}\end{table})";

	#delimit cr

/////////////////////////////////////////////////
///--- H1. Output Results to HTML
/////////////////////////////////////////////////

	esttab ${smd_panel_a_m} using "${curlogfile}.html", ${slb_panel_a_main} ${slb_esttab_opt_txt} replace
	esttab ${smd_panel_b_m} using "${curlogfile}.html", ${slb_panel_b_main} ${slb_esttab_opt_txt} append
	esttab ${smd_panel_c_m} using "${curlogfile}.html", ${slb_panel_c_main} ${slb_esttab_opt_txt} append

/////////////////////////////////////////////////
///--- H2. Output Results to RTF
/////////////////////////////////////////////////

	esttab ${smd_panel_a_m} using "${curlogfile}.rtf", ${slb_panel_a_main} ${slb_esttab_opt_txt} replace
	esttab ${smd_panel_b_m} using "${curlogfile}.rtf", ${slb_panel_b_main} ${slb_esttab_opt_txt} append
	esttab ${smd_panel_c_m} using "${curlogfile}.rtf", ${slb_panel_c_main} ${slb_esttab_opt_txt} append

/////////////////////////////////////////////////
///--- H3. Output Results to Tex
/////////////////////////////////////////////////

	esttab $smd_panel_a_m using "${curlogfile}.tex", ///
		${slb_panel_a_main} ///
 		${slb_refcat_panel_a} ///
		${slb_esttab_opt_tex} ///
		fragment $headlineAll postfoot("") replace

	esttab $smd_panel_b_m using "${curlogfile}.tex", ///
		${slb_panel_b_main} ///
 		${slb_refcat_panel_b} ///
		${slb_esttab_opt_tex} ///
		fragment prehead("") postfoot("") append

	esttab $smd_panel_c_m using "${curlogfile}.tex", ///
		${slb_panel_c_main} ///
 		${slb_refcat_panel_c} ///
		${slb_esttab_opt_tex} ///
		${slb_titling_bottom} ///
		addnotes(${slb_note}) ///
		fragment prehead("") $postAll append



/////////////////////////////////////////////////
///--- I. Out Logs
/////////////////////////////////////////////////

///--- End Log and to HTML
log close
capture noisily {
	log2html "${curlogfile}_log", replace
}

///--- to PDF
capture noisily {
	translator set Results2pdf logo off
	translator set Results2pdf fontsize 10
	translator set Results2pdf pagesize custom
	translator set Results2pdf pagewidth 11.69
	translator set Results2pdf pageheight 16.53
	translator set Results2pdf lmargin 0.2
	translator set Results2pdf rmargin 0.2
	translator set Results2pdf tmargin 0.2
	translator set Results2pdf bmargin 0.2
	translate @Results "${curlogfile}.pdf", replace translator(Results2pdf)
}
capture noisily {
  erase "${curlogfile}_log.smcl"
}