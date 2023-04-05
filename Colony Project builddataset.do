/*******************************************************/
/* Insert this code at the top of your .do file to     */
/* check one set of names against another.  Here, I    */
/* assume these are country names but anything works   */
/*******************************************************/


/*******************************************************/
/* Program to check for name mismatches                */
/*  List of standardized names kept in "names.dta"     */
/*  If current names don't all match, generates        */
/*  diagnostics file and stop execution                */
/*                                                     */
/* Syntax: namecheck varname                           */
/*  where varname is name variable used in both files  */
/* NOTE:  You first have to create a list of "correct" */
/*        names and save in "names.dta".  You also have*/
/*        to use the same variable name for the naming */
/*        variable in both locations                   */
/*******************************************************/
 
capture program drop namecheck
program define namecheck
 
quietly {
  preserve
  keep `1'
  duplicates drop
  merge 1:1 `1' using "names.dta"
  count if _merge==1
  local r1=`r(N)'
  count if _merge==2
  local r2=`r(N)'
}
  if `r1'>0 & `r2'>0 {
    quietly { 
    	drop if _merge==3
      rename _merge matchtype
      sort `1'
      gen sequence=_n
      reshape wide `1', i(sequence) j(matchtype)
      rename `1'1 `1'
      rename `1'2 standard_`1'
      order standard_`1' `1'
      drop sequence
      export excel using namelist, firstrow(variables) nolabel replace
    }
    display as smcl "Name mismatches written to {browse  "`"namelist.xls}"'"
    error(1)
  }
  else 
  	display "No name mismatches problems found."
  }
  restore
end
*end of program namecheck*

//*stanardize on World Development Indicators country names*/
wbopendata, indicator(SP.POP.TOTL;NY.GDP.PCAP.PP.KD;SP.DYN.IMRT.IN;SP.DYN.LE00.IN) long clear  /*get one variable just for the country names*/
drop if region=="NA" | region==""   /*drop entries that are aggregates, not countries*/
rename sp_pop_totl pop
rename ny_gdp_pcap_pp_kd GDPppp
rename sp_dyn_imrt_in infmort
rename sp_dyn_le00_in lifexp
keep if year==2017
save macro, replace

wbopendata, indicator(SP.POP.TOTL;NY.GDP.PCAP.PP.KD;SP.DYN.IMRT.IN;SP.DYN.LE00.IN) latest long clear  /*get one variable just for the country names*/
drop if region=="NA" | region==""   /*drop entries that are aggregates, not countries*/
rename sp_pop_totl pop2
rename ny_gdp_pcap_pp_kd GDPppp2
rename sp_dyn_imrt_in infmort2
rename sp_dyn_le00_in lifexp2
save latest, replace
use macro, clear
merge 1:1 countryname using latest, keep(master match) nogen
foreach i in pop GDPppp infmort lifexp {
  replace `i'=`i'2 if missing(`i')
}
drop *2
erase latest.dta
keep countryname
duplicates drop
sort c
save names, replace


import excel "/Users/alexanderhowell/Documents/IslandNationData1.xlsx", sheet("Sheet1") firstrow clear
rename Yearssinceindependence YSI
rename Yearssincesettled YSS
destring, replace
gen Colony=1 if YSI==0
replace Colony=0 if Colony== .
rename Name countryname
replace countryname="Bahamas, The" if countryname=="Bahamas"
replace countryname="Cabo Verde" if countryname=="Cape Verde"
replace countryname="Micronesia, Fed Sts" if countryname=="Federated States of Micronesia"
replace countryname="Hong Kong SAR, China" if countryname=="Hong Kong"
replace countryname="Papua New Guinea" if countryname=="Papau New Guinea"
replace countryname="Sint Maarten (Dutch part)" if countryname=="Sint Maarten (Dutch)"
replace countryname="St Kitts and Nevis" if countryname=="Saint Kitts and Nevis"
replace countryname="St Martin (French part)" if countryname=="St Martin (French)"
replace countryname="St Vincent and the Grenadines" if countryname=="St Vincent"
replace countryname="Trinidad and Tobago" if countryname=="Trinidad and Tobego"
replace countryname="Turks and Caicos Islands" if countryname=="Turks and Caicos"
replace countryname="Virgin Islands (US)" if countryname=="Virgin Islands"
*namecheck countryname
drop if countryname==""
merge 1:1 countryname using macro, keep(master match) nogen
reg GDPCapita2019 YSS YSI ColoFrance ColoSpain ColoDutch ColOther Colony
estat hettest
vif
estat ovtest
test YSS=0
test YSI=0
gen lnGDPC=log(GDPCapita2019)
eststo e1: reg lnGDPC YSS YSI ColoFrance ColoSpain ColoDutch ColOther Colony
estat hettest
estat ovtest
vif
test YSS=0
test YSI=0
gen lnGDPppp=log(GDPppp)
eststo e2: reg lnGDPppp YSS YSI ColoFrance ColoSpain ColoDutch ColOther Colony
gen sample=e(sample)
eststo e3: reg lnGDPppp YSS YSI ColoBrit Colony
estat hettest
estat ovtest
vif
test YSS=0
test YSI=0
esttab e1 e2 e3, nogaps title("Table 1") star(* .1 ** .05 *** .01) mlab(none) addnotes("(1) Uses GDP data from various sources." "(2) and (3) Use WDI GDP ppp data")
esttab e1 e2 e3 using tab1.txt, replace tab nogaps title("Table 1") star(* .1 ** .05 *** .01) mlab(none) addnotes("(1) Uses GDP data from various sources." "(2) and (3) Use WDI GDP ppp data")

asdoc su lnGDPppp YSS YSI ColoBrit ColoFrance ColoSpain ColoDutch ColOther Colony infmort lifexp if sample, save(DescriptiveStatistics.doc) replace title(Descriptive Statistics) font(TimesNewRoman) fs(12)
eststo e4: reg infmort YSS YSI ColoBrit Colony, robust
estat ovtest
vif
eststo e5: reg lifexp YSS YSI ColoBrit Colony
estat hettest
estat ovtest
vif
esttab e3 e4 e5, nogaps title("Table 2") star(* .1 ** .05 *** .01) mlab(none) addnotes("(3) Uses WDI GDP ppp data." "(4) uses WDI infant mortality and (5) uses WDI life expectancy data")
esttab e3 e4 e5 using tab2.txt, replace tab nogaps title("Table 2") star(* .1 ** .05 *** .01) mlab(none) addnotes("(3) Uses WDI GDP ppp data." "(4) uses WDI infant mortality and (5) uses WDI life expectancy data")
