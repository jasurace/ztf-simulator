;
; This module reads in a list of pointings, and
;  outputs a list of the pointing centers and header 
;  keywords.
;
; IDL> ztf_simdata_datacenters,'pointings.list','testfile'
;
; 4/29/16 - dropped "." out of filename
;
;
pro ztf_simdata_datacenters,pointlist,outfile,$
                                      pretimed=pretimed ; input file has times in it

start_time=systime(/seconds)

; CCD FORMAT CONSTANTS
cw=6144.      
ch=6160.
pixsize=1.02/3600. ; pixel size in arcseconds at center, 1.02 arcsec

; TIMING CONSTANTS
slewspeed=3.3    ; degrees per second
settletime=3.    ; settling time in seconds
readtime=15.     ; readout time in seconds
exptime=30.      ; exposure time in seconds

; read in the list of boresight pointing centers
if (keyword_set(pretimed) ne 1) then begin
       readcol,pointlist,telra,teldec,fieldid,filter,imtype,format='F,F,I,I,I'
endif else begin
       readcol,pointlist,telra,teldec,fieldid,filter,imtype,times,format='F,F,I,I,I,D'
endelse
nexp=n_elements(teldec)
print,'Read in ',nexp,' pointings.'

; load the header template
;restore,'header_template.sav'
hd=headfits('hd1.fits')
; reset some key values
sxdelpar,hd,'CROTA2'
sxdelpar,hd,'CDELT1'
sxdelpar,hd,'CDELT2'
sxaddpar,hd,'NAXIS1',cw
sxaddpar,hd,'NAXIS2',ch
sxaddpar,hd,'CRPIX1',cw/2.
sxaddpar,hd,'CRPIX2',ch/2.
sxaddpar,hd,'CTYPE1','RA---TAN'
sxaddpar,hd,'CTYPE2','DEC--TAN'
sxaddpar,hd,'CD1_1',-1.0*pixsize 
sxaddpar,hd,'CD1_2',0
sxaddpar,hd,'CD2_1',0
sxaddpar,hd,'CD2_2',pixsize

; initialize the time function
mjd0=57754.D ; jan 1, 2017
mjd=mjd0
time=0.D

; initialize the ccd
ccd=fltarr(cw,ch)

; open the output file
openw,unit,outfile,/get_lun

; loop over all requested exposures
for exposure=0,nexp-1 do begin

; update the time
if (exposure gt 0) then begin
slewdist=sphdist(telra[exposure],teldec[exposure],telra[exposure-1],teldec[exposure-1],/degrees)
   time_interval=max([ceil((slewdist/slewspeed)+settletime),readtime])
   time=time+exptime+time_interval
   mjd=mjd0+(time/(3600.*24.))
endif

; bypass the time calculation if input file has times
if keyword_set(pretimed) then mjd=times[exposure]


; reset the pointing center
sxaddpar,hd,'CRVAL1',telra[exposure]
sxaddpar,hd,'CRVAL2',teldec[exposure]


; for each exposure, we have 16 chips
for ccdid=0,15 do begin

; get the chip center
pos=ztf_getchipoffsets(ccdid)
sxaddpar,hd,'CRPIX1',pos[0]
sxaddpar,hd,'CRPIX2',pos[1]

; find the chip centers in RA,DEC
xyad,hd,cw/2.,ch/2.,ccdra,ccddec

; get the output filename
; convert the time
caldat,mjd+2400000.5,mon,day,yr,hr,mn,sec
mon=strcompress('000'+string(mon),/remove_all)
mon=strmid(mon,strlen(mon)-2,2)
day=strcompress('000'+string(day),/remove_all)
day=strmid(day,strlen(day)-2,2)
hr=strcompress('000'+string(hr),/remove_all)
hr=strmid(hr,strlen(hr)-2,2)
mn=strcompress('000'+string(mn),/remove_all)
mn=strmid(mn,strlen(mn)-2,2)
sec=round(sec)
sec=strcompress('000'+string(sec),/remove_all)
sec=strmid(sec,strlen(sec)-2,2)

fracday=(hr+(mn/60.)+(sec/3600.))/24.
fracday=strcompress(string(fracday),/remove_all)
fracday=strmid(fracday,2,5)

chip=strcompress('000'+string(ccdid+1),/remove_all)
chip=strmid(chip,strlen(chip)-2,2)
chip=strcompress('_c'+chip,/remove_all)

fieldidname=strcompress('000000'+string(fieldid[exposure]),/remove_all)
fieldidname=strmid(fieldidname,strlen(fieldidname)-6,6)
print,fieldidname

case filter[exposure] of
1: filtername='sg'
2: filtername='sr'
3: filtername='si'
else: filtername='unknown'
endcase

case imtype[exposure] of
0: imtypename='o'
1: imtypename='b'
2: imtypename='d'
3: imtypename='f'
else: imtypename='x'
endcase


outname='ztf_'+string(yr)+mon+day+fracday+'_'+fieldidname+'_'+filtername+chip+$
        '_'+imtypename+'.fits'
outname=strcompress(outname,/remove_all)


; print the output
print,outname,exposure,ccdid,time,mjd,fieldid[exposure],imtype[exposure],filter[exposure],ccdra,ccddec
fmt='(A40,I5,I4,D16.8,I12,I5,I5,D15.7,F12.7,F12.7,F12.7)'
printf,unit,format=fmt,outname,exposure,ccdid,mjd,fieldid[exposure],imtype[exposure],filter[exposure],telra[exposure],teldec[exposure],ccdra,ccddec

; close the ccd loop
endfor

; close the exposures loop
endfor

close,unit

print,'Total elapsed time (sec): ',systime(/seconds)-start_time

end