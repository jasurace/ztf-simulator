; start date is [year,month,day]
;
;   this version uses Eric's tiling scheme


pro ztf_sim_scansky_v2,outfile,startdate

; TIMING CONSTANTS
slewspeed=3.3    ; degrees per second
settletime=3.    ; settling time in seconds
readtime=15.     ; readout time in seconds
exptime=30.      ; exposure time in seconds

; some hardwired values
filter=2 ; using PTF convention 1=g, 2=R, 3=i
objtype=0 ; 0=object, 1=bias, 2=dark

; load the fieldid file
readcol,'ZTF_Fields_vFeb2016.txt',fieldid_def,fieldra_def,fielddec_def,junk,junk,junk,junk,junk,format='I,D,D,A,A,A,A,A',skipline=1

; load some header info
hd0=headfits('hd0.fits')
; get the observatory location
obslat=sxpar(hd0,'OBSLAT')
obslon=sxpar(hd0,'OBSLON')
print,'Observatory coordinates: ',obslat,obslon

; day conversions
doy=ymd2dn(startdate[0],startdate[1],startdate[2])
jdcnv,startdate[0],startdate[1],startdate[2],0.,jd


; get the sunrise and set times
sun_times=sunrise(doy,startdate[0],lat=obslat,lon=obslon)

print,'Sunset ',sun_times[1]
print,'Sunrise ',sun_times[0]
print,'Length of night ',sun_times[3]

; this is the initial start time for actual observations
t=1.0D*jd+(sun_times[1]/24.)-1.

; initialize at zenith 90 degrees
fieldalt=85.

; initially go negative in altitude
dir=-1.

openw,1,outfile

; let's start by putting in some bias frames
print,'Adding bias frames.'
tbias=t-(2./24.) ; start two hours before sunset
for i=0,4 do begin

; acquire the ra/dec for the current alt/az
hor2eq,90,180.,tbias,fieldra,fielddec,lat=obslat,lon=obslon



print,(tbias-jd)*24.,fieldra,fielddec
fmt='(F12.3,F12.3,I12,I5,I5,F25.10)'
printf,1,format=fmt,fieldra,fielddec,0,filter,1,tbias-2400000.5

tbias=tbias+(20./(3600.*24.))

endfor

; And a couple flats
print,'Adding flat frames.'
for i=0,2 do begin

hor2eq,90,180.,tbias,fieldra,fielddec,lat=obslat,lon=obslon

print,(tbias-jd)*24.,fieldra,fielddec
fmt='(F12.3,F12.3,I12,I5,I5,F25.10)'
printf,1,format=fmt,fieldra,fielddec,0,filter,3,tbias-2400000.5

tbias=tbias+(20./(3600.*24.))

endfor


; this loop does the slewing for the actual exposures
while (t lt (jd+(sun_times[0]/24.))) do begin

; derive LST
ct2lst,lst,obslon,dummy,t ; LST specified in hours

; where is the SUN?
sunpos,jd,sunra,sundec
sunha=(lst*15.)-sunra ; sun ha in degrees
hadec2altaz,sunha,sundec,obslat,sunalt,sunaz

; where are we pointed in RA/DEC?
;   we are slewing back and forth on the meridian
;
hor2eq,fieldalt,180.,t,fieldra,fielddec,lat=obslat,lon=obslon

; now find the closest matching field, and swap it in
d=sphdist(fieldra,fielddec,fieldra_def,fielddec_def,/degrees)
closest=min(d,minloc)

fieldid=fieldid_def[minloc]
fieldra=fieldra_def[minloc]
fielddec=fielddec_def[minloc]


print,(t-jd)*24.,sunalt,fieldalt,fieldra,fielddec
fmt='(F12.3,F12.3,I12,I5,I5,F25.10)'
printf,1,format=fmt,fieldra,fielddec,fieldid,filter,objtype,t-2400000.5

; check the scan direction
if fieldalt lt 30 then dir=1.
if fieldalt gt 150 then dir=-1.

; slewing by 7.1 degrees each time
fieldalt=fieldalt+(dir*7.1)




; increment the time
;  since this is a simple scan, just stick with the 45 second gap
t=t+(45./(3600.*24.))



; close the loop once the sun comes up
endwhile


close,1,/all

end

