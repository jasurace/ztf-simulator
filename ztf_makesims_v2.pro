pro ztf_makesims_v2,outfile,startdate


; TIMING CONSTANTS
slewspeed=3.3    ; degrees per second
settletime=3.    ; settling time in seconds
readtime=15.     ; readout time in seconds
exptime=30.      ; exposure time in seconds


; load some header info
hd0=headfits('hd0.fits')
; get the observatory location
obslat=sxpar(hd0,'OBSLAT')
obslon=sxpar(hd0,'OBSLON')
print,'Observatory coordinates: ',obslat,obslon

tbias=1.0D*startdate-(4./24.) ; start four hours early


openw,1,outfile

; biases

for i=0,19 do begin

hor2eq,90,180.,tbias+2400000.5,fieldra,fielddec,lat=obslat,lon=obslon

print,tbias,fieldra,fielddec
fmt='(F12.3,F12.3,I12,I5,I5,F25.10)'
printf,1,format=fmt,fieldra,fielddec,0,2,1,tbias

tbias=tbias+(20./(3600.*24.))

endfor

; flats

for i=0,19 do begin

hor2eq,90,180.,tbias+2400000.5,fieldra,fielddec,lat=obslat,lon=obslon

print,tbias,fieldra,fielddec
fmt='(F12.3,F12.3,I12,I5,I5,F25.10)'
printf,1,format=fmt,fieldra,fielddec,0,1,3,tbias

tbias=tbias+(30./(3600.*24.))

endfor

for i=0,19 do begin

hor2eq,90,180.,tbias+2400000.5,fieldra,fielddec,lat=obslat,lon=obslon

print,tbias,fieldra,fielddec
fmt='(F12.3,F12.3,I12,I5,I5,F25.10)'
printf,1,format=fmt,fieldra,fielddec,0,2,3,tbias

tbias=tbias+(30./(3600.*24.))

endfor

for i=0,19 do begin

hor2eq,90,180.,tbias+2400000.5,fieldra,fielddec,lat=obslat,lon=obslon

print,tbias,fieldra,fielddec
fmt='(F12.3,F12.3,I12,I5,I5,F25.10)'
printf,1,format=fmt,fieldra,fielddec,0,3,3,tbias

tbias=tbias+(30./(3600.*24.))

endfor



close,1,/all

end