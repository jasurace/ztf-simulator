;+
; NAME: suntimes
;
; PURPOSE:
; 	compute APPROXIMATE sunrise and sunset times
;
; NOTES:
; 	Uses algorithms from the
; 	Buie Lowell IDL library.
;
; 	This is not likely to be the most accurate thing in the world.
;
; 	Particularly since it doesn't account for the motion of the sun
; 	during the day in question.
;
;
; USAGE:
; 	suntimes,jd,rise,set, [/today, /lst, obsname="lick", degrees=12]
;
; INPUTS:
; KEYWORDS:
;		degrees=	how many degrees below the horizon? 
;					Default is 0.25, so the sun is just tangent to the horizon
; 		/lst		return results in LST, not CT
; 
; OUTPUTS:
;
; HISTORY:
; 	Began 2005-07-14 16:07:24 by Marshall Perrin 
; 		see 'obsplan.pro' from the Buie library for algorithm source.
;-

PRO suntimes,jd,rise,set,today=today,date=date,obsname=obsname,$
	degrees=degrees,lst=uselst,print=print

	gmt_offset_days = gmt_offsec()/84600.
	gmt_offset_hours = gmt_offsec()/3600.

	if n_elements(degrees) eq 0 then degrees=0.25 
	if ~(keyword_set(jd)) and ~(keyword_set(date)) then today=1	
	if keyword_set(today) then begin
		; julday by itself doesn't know about time zones.
		; So you have to add in an offset to take into account the
		; fact that the computer's clock may not be in GMT.
		jd = julday()+gmt_offset_days
		daycnv,jd-gmt_offset_days,yr,mon,day,hr
		date = [yr,mon,day,hr]
	endif else $
	if keyword_set(date) then begin
		if n_elements(date) eq 3 then hr = 0 else hr = date[3]
		jdcnv,date[0],date[1],date[2],hr,jd
		jd += gmt_offset_days
	endif

	if ~(keyword_set(obsname)) then obsname='lick'

	observatory,obsname,obs
	lat=obs.latitude*!dtor
	lon=obs.longitude*!dtor
	alt=obs.altitude

	; Sun position at input JD
    sunpos,jd,sunra,sundec,/RADIAN

  ; Define night, Sun set to sun rise.
	
	; find jd of midnight
;	daycnv,jd,y,m,d,h
;	jdcnv,y,m,d,gmt_offset_hours,jdlclmid

   am  = airmass(jd,sunra,sundec,lat,lon,alt=alt,lha=lha,lst=lst)
   hatojd,!dpi,sunra,lst,jd,jdlclmid ; jd of nearest local midnight
   lsidtim,jdlclmid,lon,midlst       ; LST at local midnight
   jdofmid = float(long(jdlclmid+0.5d0))-0.5d0
   jdstr,jdofmid,100,thisdate
   
   ; alt needs to be NEGATIVE to be below the horizon!
   altoha,(-1)*degrees/!radeg,sundec,lat,sunhorzha,sunhorztype
   
   ; JD of sunset/sunrise, AT, NT, CT
   jdsset   = jdlclmid - (!dpi-sunhorzha)/2.0d0/!dpi
   jdsrise  = jdlclmid + (!dpi-sunhorzha)/2.0d0/!dpi

	daycnv,jdsset,set_y,set_m,set_d,set_h
	daycnv,jdsrise,rise_y,rise_m,rise_d,rise_h

	set = set_h-gmt_offset_hours
	if set lt 0 then set += 24.0
	rise = rise_h-gmt_offset_hours

;	print,"set:  ", set
;	print,"rise: ", rise

	if keyword_set(uselst) then begin
		ct2lst,rise,obs.longitude*(-1),tz,jdsrise
		ct2lst,set,obs.longitude*(-1),tz,jdsset
	endif


if keyword_set(print) then begin
	if keyword_set(uselst) then print,"Sun times in LST:" else print, "Sun times in PST:"
	print,"Set:", set
	print,"Rise:", rise
endif
	

end