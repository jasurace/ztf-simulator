;
;  Purely artifical set of data
;  Based on a model, but allows debug of code
;
; v8 - modified to use pan-starrs instead of SDSS. Also some
;      tweaks to the streak table to add celestial coordinates.
;
; v7 - added streaks
;
; v6 - support for real differences between bands
;      fixed some positional keywords that weren't reset
;      also fixed some other header issues
;
; v5 - added transients and radhits, some bug fixes
;
; v4 - changed wcs output representation to PC from CD
;      options of running on ops system
;
; v3 - reworked detector geometry
;      added bias option
;
; v2 - changed image output packaging
;
; ztf_simdata_placepsf_v3,'skyscan_exp_5.list','/Volumes/Douroucouli/scr/'
; ztf_simdata_placepsf_v5,'test_expansion.tbl','/disk2/ztf/'
;
; idl -e "ztf_simdata_placepsf_v5,'test_expansion.tbl','/disk2/ztf/'" > & test.out &
;idl -e "ztf_simdata_placepsf_v5,'sim_expansion_220616_0.list','/stage/ztf-test3/jason/sim220616/',/compress,/ops" >& node01.out &
;
; on thoth
; ztf_simdata_placepsf_v7,'temp.list','/Users/Jason/'
;
;  ztf_simdata_placepsf_v8,'temp.list','/stage/ztf-work-ztfjs/sim_test/',/ops
;
pro ztf_simdata_placepsf_v8,pointlist,dest,$
                         compress=compress, $ ; apply the RICE compression
                         nowcs=nowcs,$ ; strip out the wcs
                         pcmatrix=pcmatrix,$ ; use pc matrix instead of CD
                         ops=ops ; operate on the ops system instead of testbed

                         
start_time=systime(/seconds)

; CCD FORMAT CONSTANTS
cw=6144.  ; width    
ch=6160.  ; height
pixsize=1.02/3600. ; pixel size in arcseconds at center, 1.02 arcsec
so=24 ; slow overscan
fo=40 ; fast overscan


; SATURATION AND SCALING PARAMETERS
satmag=14.
satval=55000.
gain=2.

; PSF TYPE
psf=readfits('psf_gauss2.fits',psf_hd)
pw=sxpar(psf_hd,'NAXIS1')
buf=pw/2.
psf_peak=max(psf)
scalefactor=satval/(10^(satmag/(-2.5))*psf_peak)
magzp=13+2.5*alog10(satval/psf_peak)

; FLATFIELD DEFINITION
;flatfield=readfits('ztf_flat.fits')
flatfield_r=readfits('ztf_flat_r.fits')
flatfield_g=readfits('ztf_flat_g.fits')
flatfield_i=readfits('ztf_flat_i.fits')


; read in the list of boresight pointing centers
readcol,pointlist,filename,exposure,ccdid,mjd,fieldid,imtype,filter,telra,teldec,ccdra,ccddec,format='A,F,F,D,F,F,F,F,F'
nimages=n_elements(filename)
print,'Read in ',nimages,' CCDs to simulate.'



; load the header template
;restore,'header_template.sav'
hd=headfits('hd1_v2.fits')
hd0=headfits('hd0_v2.fits')

; this is the fakefile for writing the header
fakefile=0
sxdelpar,hd0,['NAXIS1','NAXIS2']

; reset some key values in the CCD image header
sxaddpar,hd,'NAXIS1',cw+pw
sxaddpar,hd,'NAXIS2',ch+pw
sxaddpar,hd,'CRPIX1',(cw+pw)/2.
sxaddpar,hd,'CRPIX2',(ch+pw)/2.
sxaddpar,hd,'CTYPE1','RA---TAN'
sxaddpar,hd,'CTYPE2','DEC--TAN'
sxaddpar,hd,'CD1_1',-1.0*pixsize 
sxaddpar,hd,'CD1_2',0
sxaddpar,hd,'CD2_1',0
sxaddpar,hd,'CD2_2',pixsize
sxaddpar,hd,'MAGZP',magzp,' model mag zeropoint (includes exptime)'
sxaddpar,hd,'GAIN',gain 

; fix an issue in the header related to making multiextension
sxdelpar,hd,'XTENSION'
sxaddpar,hd,'XTENSION','IMAGE',before='SIMPLE'
sxdelpar,hd,'SIMPLE'
sxaddpar,hd,'PCOUNT',0,'Required keyword; must = 0',after='NAXIS2'
sxaddpar,hd,'GCOUNT',1,'Required keyword; must = 1',after='PCOUNT'

; fix issues in the primary header unit
sxaddpar,hd0,'ZTFFLAG',long(1),' 1=ZTF, 0=other'

; fix the header datatype
sxaddpar,hd,'BITPIX',16

; get the observatory location
obslat=sxpar(hd0,'OBSLAT')
obslon=sxpar(hd0,'OBSLON')

; initialize the ccd
ccd=fltarr(cw+pw,ch+pw)

; initialize the output file arrays
readout_out=fltarr(cw/2,ch/2,4)
bias_out=fltarr(fo,ch/2,4)


;-----------------------------------
; loop over all requested exposures
;-----------------------------------
for image=0,nimages-1 do begin
;for image=0,5 do begin

print,filename[image],telra[image],teldec[image],long(ccdid[image])

; reset the pointing center
sxaddpar,hd,'CRVAL1',telra[image]
sxaddpar,hd,'CRVAL2',teldec[image]
sxaddpar,hd,'TELRA',telra[image]
sxaddpar,hd,'TELDEC',teldec[image]
sxaddpar,hd0,'OBJRAD',telra[image]
sxaddpar,hd0,'OBJDECD',teldec[image]
sxaddpar,hd0,'RAD',telra[image]
sxaddpar,hd0,'DECD',teldec[image]
sxaddpar,hd0,'TELRA',telra[image]
sxaddpar,hd0,'TELDEC',teldec[image]
radec,telra[image],teldec[image],ihr,imin,xsec,ideg,imn,xsc
sxaddpar,hd0,'OBJRA',strcompress(string(ihr)+':'+string(imin)+':'+string(xsec),/remove_all),'Requested J2000.0  HH:MM:SS.SSS'
sxaddpar,hd0,'OBJDEC',strcompress(string(ideg)+':'+string(imn)+':'+string(xsc),/remove_all),'Requested J2000.0  sDD:MM:SS.SSS'
sxaddpar,hd0,'RA',strcompress(string(ihr)+':'+string(imin)+':'+string(xsec),/remove_all),'Requested J2000.0  HH:MM:SS.SSS'
sxaddpar,hd0,'DEC',strcompress(string(ideg)+':'+string(imn)+':'+string(xsc),/remove_all),'Requested J2000.0  sDD:MM:SS.SSS'

; update header time keywords
sxaddpar,hd0,'OBSMJD',mjd[image],'[day] MJD corresponding to UTC-OBS'
jd=mjd[image]+2400000.5D
sxaddpar,hd0,'OBSJD',jd,'[day] Julian day corresponds to UTC-OBS',format='G19.12'
hjd=helio_jd(jd-2400000.,telra[image],teldec[image])
sxaddpar,hd0,'HJD',hjd,'[day] Heliocentric Julian Day'

; construct the time string
daycnv,jd,yr,mn,day,hr
mn=strcompress('000'+string(mn),/remove_all)
mn=strmid(mn,strlen(mn)-2,2)
day=strcompress('000'+string(day),/remove_all)
day=strmid(day,strlen(day)-2,2)
minutes=(hr-floor(hr))*60.
sec=(minutes-floor(minutes))*60.
minutes=floor(minutes)
hr=floor(hr)
hr=strcompress('000'+string(hr),/remove_all)
hr=strmid(hr,strlen(hr)-2,2)
minutes=strcompress('000'+string(minutes),/remove_all)
minutes=strmid(minutes,strlen(minutes)-2,2)
if (sec ge 10) then sec=string(sec) else sec=strcompress('0'+string(sec),/remove_all)
datestr=string(yr)+'-'+mn+'-'+day+'T'+hr+':'+minutes+':'+sec
datestr=strcompress(datestr,/remove_all)
sxaddpar,hd0,'UTC-OBS',datestr,'UTC time shutter opens'
sxaddpar,hd0,'DATE-OBS',datestr,'UTC time shutter opens'
;sxaddpar,hd0,'OCS_TIME',datestr,'UTC date-time for OCS calcs'

; WEATHER DATA
sxaddpar,hd0,'UT_WEATH',datestr,'UT of weather data'


; EXPOSURE TIME
case imtype[image] of
0: exptime=30.
1: exptime=0.
2: exptime=30.
3: exptime=30.
else:
endcase
sxaddpar,hd0,'EXPOSURE',exptime
sxaddpar,hd0,'EXPTIME',exptime
sxaddpar,hd0,'AEXPTIME',exptime

; SHUTTER TIMES
sxaddpar,hd0,'SHUTOPEN',datestr,'UTC time shutter opens'
; this is a dummy for now
sxaddpar,hd0,'SHUTCLSD',datestr,'UTC time shutter opens'
sxaddpar,hd0,'END_TIME',datestr,'End of observation time'
sxaddpar,hd0,'DATE',datestr,'File write date'

; add LST
ct2lst,lst,obslon,dummy,jd ; LST specified in hours
sexlst=long(sixty(lst)) ; convert hours to sexagesimal
sxaddpar,hd0,'OBSLST',strcompress(string(sexlst[0])+':'+string(sexlst[1])+':'+string(sexlst[2]),/remove_all),'Mean LST corresponding to UTC-OBS'

; HOUR ANGLE AND TELESCOPE PARAMETERS
ha=lst-(telra[image]/15.) ; ha defined in hours
sexha=long(sixty(ha)) ; converty to sexagesimal
sxaddpar,hd0,'HOURANG',strcompress(string(sexha[0])+':'+string(sexha[1])+':'+string(sexha[2]),/remove_all),'Mean HA (sHH:MM:SS.S) based on LMST at UTC-OBS'
hadec2altaz,ha*15.,teldec[image],obslat,alt,az ; input is ha in degrees
sxaddpar,hd0,'ELEVATION',alt,'[deg] Telescope elevation'
sxaddpar,hd0,'AZIMUTH',az,'[deg] Telescope azimuth'
sxaddpar,hd0,'AIRMASS',airmass(alt),'Telescope air mass'
sxaddpar,hd0,'DOME_AZ',az,'[deg] Dome azimuth'

; MOON
moonpos,jd,moonra,moondec
mphase,jd,moonillfrac
sxaddpar,hd0,'MOONRA',moonra,'[deg] Moon right ascension J2000.0'
sxaddpar,hd0,'MOONDEC',moondec,'[deg] Moon declination J2000.0'
sxaddpar,hd0,'MOONILLF',moonillfrac,'Moon illuminated fraction'
moonha=(lst*15.)-moonra
hadec2altaz,moonha,moondec,obslat,moonalt,moonaz
sxaddpar,hd0,'MOONALT',moonalt,'[deg] Moon altitude'
sxaddpar,hd0,'MOONPHASE',moonphase(jd),'[deg] Moon phase'


; SUN
sunpos,jd,sunra,sundec
sunha=(lst*15.)-sunra ; sun ha in degrees
hadec2altaz,sunha,sundec,obslat,sunalt,sunaz
sxaddpar,hd0,'SUNALT',sunalt,'[deg] Sun altitude'
sxaddpar,hd0,'SUNAZ',sunaz,'[deg] Sun azimuth'

; IMTYPES
case imtype[image] of
0: sxaddpar,hd0,'IMGTYP','object'
1: sxaddpar,hd0,'IMGTYP','bias'
2: sxaddpar,hd0,'IMGTYP','dark'
3: sxaddpar,hd0,'IMGTYP','flat'
else: sxaddpar,hd0,'IMGTYP','unknown'
endcase

case imtype[image] of
0: sxaddpar,hd0,'IMAGETYP','object'
1: sxaddpar,hd0,'IMAGETYP','bias'
2: sxaddpar,hd0,'IMAGETYP','dark'
3: sxaddpar,hd0,'IMAGETYP','flat'
else: sxaddpar,hd0,'IMAGETYP','unknown'
endcase

; FILENAMES
sxaddpar,hd0,'FILENAME',filename[image]
sxaddpar,hd0,'ORIGNAME',filename[image]

; DOMESTAT
case imtype[image] of
0: sxaddpar,hd0,'DOMESTAT','open'
1: sxaddpar,hd0,'DOMESTAT','closed'
2: sxaddpar,hd0,'DOMESTAT','closed'
3: sxaddpar,hd0,'DOMESTAT','closed'
else: sxaddpar,hd0,'DOMESTAT','unknown'
endcase

; WEATHER
sxaddpar,hd0,'HUMIDITY',0.4+randomn(seed0)
sxaddpar,hd0,'PRESSURE',750.+3.*randomn(seed0)
sxaddpar,hd0,'TEMPTURE',23.+randomn(seed0)
sxaddpar,hd0,'WINDSPD',9.+randomn(seed0)
sxaddpar,hd0,'WINDDIR',19+2.*randomn(seed0)

; FIELDID
sxaddpar,hd0,'FIELDID',long(fieldid[image])

; blank the ccd
;  this takes nearly 5 seconds!
ccd[*]=0.

; reset the chip center
pos=ztf_getchipoffsets(ccdid[image])
sxaddpar,hd,'CRPIX1',pos[0]+buf
sxaddpar,hd,'CRPIX2',pos[1]+buf


; set some header keywords specific to this image
sxaddpar,hd0,'CCD_ID',long(ccdid[image]+1)
sxaddpar,hd,'CCD_ID',long(ccdid[image]+1)
print,long(ccdid[image]+1)
;sxaddpar,hd,'FPA',long(ccdid[image])
sxaddpar,hd0,'FILTERID',long(filter[image]),'Filter I.D.'
case filter[image] of
    1: sxaddpar,hd0,'FILTER','Sloan g','Filter name'
    2: sxaddpar,hd0,'FILTER','Sloan r','Filter name'
    3: sxaddpar,hd0,'FILTER','Sloan i','Filter name'
else:  sxaddpar,hd0,'FILTER','Unknown','Filter name'
endcase
case filter[image] of
    1: sxaddpar,hd0,'FILPOS',1,'Filter position number'
    2: sxaddpar,hd0,'FILPOS',2,'Filter position number'
    3: sxaddpar,hd0,'FILPOS',3,'Filter position number'
else:  sxaddpar,hd0,'FILPOS',1,'Filter position number'
endcase


;----------------------------------------------------
; get the number of transients, radhits, and streaks
;  this is for the whole ccd, not per quadrant
nradhits=1+floor(20*randomu(rad_seed))
if imtype[image] eq 1 then nradhits=0
print,nradhits,' Radiation Hits per this CCD'
; assume ptf found 20 transient per 300 exposures,
;   each of which was 7.7 square degrees, or 1 per 115 square degrees, roughly
; each ZTF ccd is 2.9 sq deg, so one transient every 40 images
p=randomu(trans_seed)
ntransients=0
if (p gt (39./40.)) then ntransients=1
if (p gt 0.999) then ntransients=2
ntransients=20   ;  this is a diagnostic code 
print,ntransients,' transients on this CCD.'
; now the streaks
;  test to see if a long streak is present
p=randomu(trans_seed)
if (p gt 0.9) then longstreak=1 else longstreak=0
;longstreak=1 ; long streak test switch
if longstreak eq 1 then print,'Longstreak is present.' else print,'No longstreak.'
nstreaks=fix(5.*abs(randomn(trans_seed)))
;nstreaks=100 ; short streaks test switch
print,nstreaks,' short streaks.'

;open an output table file for transients
tablename2=strcompress(dest+strmid(filename[image],0,strlen(filename[image])-5)+'_transient.tbl',/remove_all)
openw,unit2,tablename2,/get_lun

if (imtype[image] eq 0) then begin

; retrieve PS1-DR1 sources
; note that this gets the center from the input file
;   it does not recompute it.
print,'Querying PAN-STARRS DR1.'

;sdss=queryvizier('sdss9',[ccdra[image],ccddec[image]],75,CONSTRAINT='rmag<20.5,mode=1')
    
if keyword_set(ops) then begin

ps1=ps1_cone_struct_index(ccdra[image],ccddec[image],(75./60),/verbose,path='/stage/ztf-work-ztfjs/ps1/decslice/')

endif else begin

ps1=ps1_cone_struct_index(ccdra[image],ccddec[image],(75./60),/verbose,path='/Users/Jason/work/ps1/')

endelse


; fallback rules in case we're outside the PS1 footprint
sz=size(ps1)
if (sz[0] eq 0) then begin
   print,'No PAN-STARRS sources found. Switching to fallback data around Arp 220.'
ps1=ps1_cone_struct_index(233.0,23.0,(75./60),/verbose,path='/stage/ztf-work-ztfjs/ps1/decslice/')
   simtype=1
   sxaddpar,hd,'CRVAL1',233.0
   sxaddpar,hd,'CRVAL2',23.0
   pos=ztf_getchipoffsets(0)
   sxaddpar,hd,'CRPIX1',pos[0]+buf
   sxaddpar,hd,'CRPIX2',pos[1]+buf
endif else begin
   simtype=0
endelse

nobj=n_elements(ps1.ra)


; convert to flux
;   we define saturation (peak) for mag=13
catra=ps1.ra
catdec=ps1.dec

; set which catalog magnitudes to use
case filter[image] of
    1: catmag=ps1.gmag
    2: catmag=ps1.rmag
    3: catmag=ps1.imag
else:  catmag=ps1.rmag
endcase

; also transfer errors
case filter[image] of
    1: caterr=ps1.gerr
    2: caterr=ps1.rerr
    3: caterr=ps1.ierr
else:  caterr=ps1.rerr
endcase

rflux=10^(catmag/(-2.5)) ; convert to flux

; switch to x,y and see what is on-chip
;  this is also where we check to see what is a good detection
adxy,hd,ps1.ra,ps1.dec,x,y
onchip=where((x gt buf)and(y gt buf)and(x lt cw+buf-1)and(y lt ch+buf-1)and(catmag gt -10)and (caterr gt -10),nonchip)
print,long(nonchip),' PS1 sources on-chip.'

;open an output table file for photometry
tablename=strcompress(dest+strmid(filename[image],0,strlen(filename[image])-5)+'.tbl',/remove_all)
openw,unit,tablename,/get_lun

;open an output table file for transients
tablename2=strcompress(dest+strmid(filename[image],0,strlen(filename[image])-5)+'_transient.tbl',/remove_all)
openw,unit2,tablename2,/get_lun

;---------------------------------------------------------
; embed the artificial sources
for i=0.,nonchip-1 do begin
  x0=floor(x[onchip[i]]-buf)
  y0=floor(y[onchip[i]]-buf)
  x1=x0+pw-1
  y1=y0+pw-1
 ccd[x0:x1,y0:y1]=ccd[x0:x1,y0:y1]+rflux[onchip[i]]*scalefactor*psf
  printf,unit,catra[onchip[i]],catdec[onchip[i]],catmag[onchip[i]]
endfor

;------------------------------------------------------
; embed transients
for i=0,ntransients-1 do begin
 txc=floor(buf+(cw-buf)*randomu(transient_seed))
 tyc=floor(buf+(ch-buf)*randomu(transient_seed))
 tmag=17+2*randomn(transient_seed)
 tflux=10^(tmag/(-2.5))
 x0=txc-buf
 y0=tyc-buf
 x1=x0+pw-1
 y1=y0+pw-1
 ccd[x0:x1,y0:y1]=ccd[x0:x1,y0:y1]+tflux*scalefactor*psf
 xyad,hd,txc,tyc,tra,tdec
 print,'Transient inserted at ',tra,tdec,txc,tyc,tmag
 printf,unit2,tra,tdec,txc,tyc,tmag,0
endfor

;---------------------------------------------------
; insert the long streak
if longstreak eq 1 then begin

print,'Inserting longstreak.'

tablename3=strcompress(dest+strmid(filename[image],0,strlen(filename[image])-5)+'_longstreak.tbl',/remove_all)
openw,unit3,tablename3,/get_lun

streakmag=14+5.*randomu(trans_seed)
print,'Streakmag ',streakmag
streakflux=10^(streakmag/(-2.5)) ; convert to flux


; which case are we?
lscase=fix(1+6.*randomu(transient_seed))
print,lscase

case lscase of
1: begin
   xls1=100.
   yls1=100+5900*randomu(transient_seed)
   xls2=100+5900*randomu(transient_seed)
   yls2=5900.
   end
2: begin
   xls1=100.
   yls1=100+5900*randomu(transient_seed)
   xls2=5900.
   yls2=100+5900*randomu(transient_seed)
   end
3: begin
   xls1=100.
   yls1=100+5900*randomu(transient_seed)
   xls2=100+5900*randomu(transient_seed)
   yls2=100.
   end
4: begin
   xls1=100+5900*randomu(transient_seed)
   yls1=5900.
   xls2=5900.
   yls2=100+5900*randomu(transient_seed)
   end
5: begin
   xls1=5900.
   yls1=100+5900*randomu(transient_seed)
   xls2=100+5900*randomu(transient_seed)
   yls2=100.
   end
6: begin
   xls1=100+5900*randomu(transient_seed)
   yls1=5900.
   xls2=100+5900*randomu(transient_seed)
   yls2=100.
   end
endcase


print,'Start ',xls1,yls1
print,'Stop  ',xls2,yls2

printf,unit3,streakmag,xls1,yls1,xls2,yls2

slope=(yls1-yls2)/(xls1-xls2)
print,'Slope ',slope

if xls2 gt xls1 then increment=.01 else increment=-0.01

for xls=xls1,xls2,increment do begin

yls=yls1+slope*(xls-xls1)



  x0=round(xls)-buf
  y0=round(yls)-buf
  x1=x0+pw-1
  y1=y0+pw-1
 ccd[x0:x1,y0:y1]=ccd[x0:x1,y0:y1]+streakflux*scalefactor*psf/100.
 
endfor

endif
; end the longstreak insertion




;-------------------------------------------------------
; embed the short streaks

if nstreaks gt 0 then begin

tablename4=strcompress(dest+strmid(filename[image],0,strlen(filename[image])-5)+'_shortstreak.tbl',/remove_all)
openw,unit4,tablename4,/get_lun
printf,unit4,'mag,ra,dec,length,position_angle'

endif



for i=0,nstreaks-1 do begin

streakmag=15+5.*randomu(trans_seed)
print,'Streakmag ',streakmag
streakflux=10^(streakmag/(-2.5)) ; convert to flux


xstreak=fix(200+5900*randomu(trans_seed))
ystreak=fix(200+5900*randomu(trans_seed))
print,'Starting point ',xstreak,ystreak

streaklength=3+fix(40.*randomu(trans_seed))
print,'Streaklength ',streaklength

streakangle=360.*randomu(trans_seed)
print,'Streakangle ',streakangle

xyad,hd,xstreak,ystreak,xstreak_ra,ystreak_dec

printf,unit4,streakmag,xstreak_ra,ystreak_dec,streaklength,streakangle

for j=0,streaklength do begin

xss=xstreak+j*cos(streakangle*3.14159/180.)
yss=ystreak+j*sin(streakangle*3.14159/180.)


  x0=round(xss)-buf
  y0=round(yss)-buf
  x1=x0+pw-1
  y1=y0+pw-1
 ccd[x0:x1,y0:y1]=ccd[x0:x1,y0:y1]+streakflux*scalefactor*psf
 
 
endfor


endfor  ; end the streak loop



endif else begin; close the loop for embedding objects
  simtype=2
endelse

;------------------------------------------------------
; retrim the image to eliminate the buffer space
trimccd=ccd[buf:cw+buf-1,buf:ch+buf-1]
sxaddpar,hd,'CRPIX1',pos[0]
sxaddpar,hd,'CRPIX2',pos[1]

; test to see if the image is filled
if (simtype eq 0)and(ztf_isfilled(trimccd) eq 0) then simtype=2
sxaddpar,hd0,'SIMTYPE',long(simtype),' 0|PS1-DR1 1|Fallback 2|NotFilled'
print,'Checking source filling factor. Flag set to ',long(simtype)

; add the simulator version number
sxaddpar,hd0,'SIMVER',long(8),' Image Simulator Version'

; apply saturation
trimccd=ztf_sim_saturation(trimccd,satval)

; add the dark sky background
case imtype[image] of
0: trimccd=ztf_sim_skybackground(trimccd,magzp,filter[image])
1: 
2:
3: trimccd=trimccd+20.e3
else: 
endcase


; add the excess brightness from the moon
;http://articles.adsabs.harvard.edu//full/1991PASP..103.1033K/0001034.000.html
; compute the moon esb

; apply the flatfield
case filter[image] of
    1: trimccd=trimccd*flatfield_g
    2: trimccd=trimccd*flatfield_r
    3: trimccd=trimccd*flatfield_i
else:  trimccd=trimccd*flatfield_r
endcase


; add the radiation hits
for i=0,nradhits-1 do begin
 radhit_flux=9000.+2000.*randomu(rad_seed)
 rxc=20+floor((cw-40)*randomu(rad_seed))
 ryc=20+floor((ch-40)*randomu(rad_seed))
 trimccd[rxc,ryc]=trimccd[rxc,ryc]+radhit_flux
 xyad,hd,rxc,ryc,rra,rdec
 print,'Adding radhit x,y,flux = ',rra,rdec,rxc,ryc,radhit_flux
 printf,unit2,rra,rdec,rxc,ryc,radhit_flux,1
endfor

close,/all


; add shot noise
;   using gaussian approximation since it is faster
trimccd=trimccd+sqrt(trimccd/gain)*randomn(seed,cw,ch)

; optional test output
;writefits,'/Users/jason/testfile.fits',fakefile,hd0
;writefits,'/Users/jason/testfile.fits',trimccd,hd,/append

; now cut out the quadrants and loop over them
for i=0,3 do begin

; identify which of the four readouts, per e2v docs
case i of 
0: readout=trimccd[0:(cw/2)-1,0:(ch/2)-1]  ; E
1: readout=trimccd[cw/2:cw-1,0:(ch/2)-1]   ; F
2: readout=trimccd[cw/2:cw-1,(ch/2):ch-1]  ; G
3: readout=trimccd[0:(cw/2)-1,(ch/2):ch-1] ; H
endcase

sz_readout=size(readout)

; transpose as per e2v docs
case i of
0: ; do nothing
1: readout=rotate(readout,5)
2: readout=rotate(readout,2)
3: readout=rotate(readout,7)
endcase




; add the bias pattern
readout=ztf_simaddbias(readout,40,24)
sz_bias=size(readout)


; add the readout noise
readout=readout+(5.4/gain)*randomn(seed,sz_bias[1],sz_bias[2])

; at this point we have a single readout image with the bias
;   strip still attached. 

; we now split those apart and store them since they want the bias strips
;   attached after the readout strips! Arrghh!


bias_out[*,*,i]=readout[sz_bias[1]-fo:sz_bias[1]-1,0:(ch/2)-1]
readout_out[*,*,i]=readout[0:(cw/2)-1,0:(ch/2)-1]

; close the readout loop
endfor


; set up the outputfile
filebase=strmid(filename[image],0,strlen(filename[image])-5)
 outfile=strcompress(dest+filebase+'.fits',/remove_all)
 writefits,outfile,fakefile,hd0

; fix nagging issue in the WCS
sxaddpar,hd,'NAXIS1',floor(cw/2)
sxaddpar,hd,'NAXIS2',floor(ch/2)


; initialize extname flag
extname=1

; write the readout extensions
for i=0,3 do begin

case i of 
0: begin
   hd_wcs=hd
   if keyword_set(pcmatrix) then begin
        sxaddpar,hd_wcs,'CDELT1',0.00028333
        sxaddpar,hd_wcs,'CDELT2',0.00028333
        sxdelpar,hd_wcs,['CD1_2','CD2_1','CD1_1','CD2_2']
        sxaddpar,hd_wcs,'PC1_1',-1.0
        sxaddpar,hd_wcs,'PC2_2',1.0
        endif
   sxaddpar,hd_wcs,'CRPIX1',pos[0]
   sxaddpar,hd_wcs,'AMP_ID',0
   ;sxaddpar,hd_wcs,'DATASEC','[1:3072,1:3080]'
   ;sxaddpar,hd_wcs,'DETSEC','[1:3072,1:3080]'
   end
1: begin
   hd_wcs=hd
   sxaddpar,hd_wcs,'CRPIX1',pos[0]-(cw/2.)
   xyad,hd_wcs,(cw/2)-1,0,r,d ; this is the new 0,0
   sxaddpar,hd_wcs,'CD1_1',0.00028333
   sxaddpar,hd_wcs,'CD2_2',0.00028333
   adxy,hd_wcs,r,d,x,y
   sxaddpar,hd_wcs,'CRPIX1',sxpar(hd_wcs,'CRPIX1')-x
   if keyword_set(pcmatrix) then begin
        sxaddpar,hd_wcs,'CDELT1',0.00028333
        sxaddpar,hd_wcs,'CDELT2',0.00028333
        sxdelpar,hd_wcs,['CD1_2','CD2_1','CD1_1','CD2_2']
        sxaddpar,hd_wcs,'PC1_1',1.0
        sxaddpar,hd_wcs,'PC2_2',1.0
        endif
   sxaddpar,hd_wcs,'AMP_ID',1
   ;sxaddpar,hd_wcs,'DATASEC','[1:3072,1:3080]'
   ;sxaddpar,hd_wcs,'DETSEC','[6144:3073,1:3080]'
   end
2: begin
   hd_wcs=hd
   sxaddpar,hd_wcs,'CRPIX1',pos[0]-(cw/2.)
   sxaddpar,hd_wcs,'CRPIX2',pos[1]-(ch/2)
   xyad,hd_wcs,(cw/2)-1,(ch/2)-1,r,d ; this is the new 0,0
   sxaddpar,hd_wcs,'CD1_1',0.00028333
   sxaddpar,hd_wcs,'CD2_2',-0.00028333
   adxy,hd_wcs,r,d,x,y
   sxaddpar,hd_wcs,'CRPIX1',sxpar(hd_wcs,'CRPIX1')-x
   sxaddpar,hd_wcs,'CRPIX2',sxpar(hd_wcs,'CRPIX2')-y
   if keyword_set(pcmatrix) then begin
        sxaddpar,hd_wcs,'CDELT1',0.00028333
        sxaddpar,hd_wcs,'CDELT2',0.00028333
        sxdelpar,hd_wcs,['CD1_2','CD2_1','CD1_1','CD2_2']
        sxaddpar,hd_wcs,'PC1_1',1.0
        sxaddpar,hd_wcs,'PC2_2',-1.0
        endif
   sxaddpar,hd_wcs,'AMP_ID',2
   ;sxaddpar,hd_wcs,'DATASEC','[1:3072,1:3080]'
   ;sxaddpar,hd_wcs,'DETSEC','[6144:3073,6160:3081]'
   end
3: begin
   hd_wcs=hd
   sxaddpar,hd_wcs,'CRPIX1',pos[0]
   sxaddpar,hd_wcs,'CRPIX2',pos[1]-(ch/2)
   xyad,hd_wcs,0,(ch/2)-1,r,d ; this is the new 0,0
   sxaddpar,hd_wcs,'CD1_1',-0.00028333
   sxaddpar,hd_wcs,'CD2_2',-0.00028333
   adxy,hd_wcs,r,d,x,y
   sxaddpar,hd_wcs,'CRPIX1',pos[0]
   sxaddpar,hd_wcs,'CRPIX2',sxpar(hd_wcs,'CRPIX2')-y
   if keyword_set(pcmatrix) then begin
        sxaddpar,hd_wcs,'CDELT1',0.00028333
        sxaddpar,hd_wcs,'CDELT2',0.00028333
        sxdelpar,hd_wcs,['CD1_2','CD2_1','CD1_1','CD2_2']
        sxaddpar,hd_wcs,'PC1_1',-1.0
        sxaddpar,hd_wcs,'PC2_2',-1.0
        endif
   sxaddpar,hd_wcs,'AMP_ID',3
   ;sxaddpar,hd_wcs,'DATASEC','[1:3072,1:3080]'
   ;sxaddpar,hd_wcs,'DETSEC','[1:3072,6160:3081]'
   end
endcase

; tweak the rn, gain, etc
sxaddpar,hd_wcs,'GAIN',gain+(i/100.)
sxaddpar,hd_wcs,'READNOI',5.0+(i/100.)
sxaddpar,hd_wcs,'DARKCUR',0.10+(i/100.)

; add the extension running tally number
sxaddpar,hd_wcs,'EXTNAME',string(extname)
extname=extname+1

; write the extension
writefits,outfile,uint(readout_out[*,*,i]),hd_wcs,/append
   
   
endfor


; strip the wcs out of the bias strips
hd_bias=hd_wcs
sxdelpar,hd_bias,['CRPIX1','CRPIX2']
sxdelpar,hd_bias,['CRVAL1','CRVAL2']
sxdelpar,hd_bias,['CTYPE1','CTYPE2']
sxdelpar,hd_bias,['CD1_1','CD1_2','CD2_1','CD2_2']

; write the bias strips
for i=0,3 do begin

   sxaddpar,hd_bias,'EXTNAME',string(extname)
   extname=extname+1
   sxaddpar,hd_bias,'AMP_ID',i
   sxaddpar,hd_bias,'GAIN',gain+(i/100.)
   sxaddpar,hd_bias,'READNOI',5.0+(i/100.)
   sxaddpar,hd_bias,'DARKCUR',0.10+(i/100.)
   
   writefits,outfile,uint(bias_out[*,*,i]),hd_bias,/append
   
endfor



; compress the data with fpack
if keyword_set(ops) then begin
     cmd='/ztf/ops/sw/stable/ext/bin/fpack -i2f -r -w -D -Y -q 4 '+outfile
endif else begin
     cmd='~/Dropbox/sim/fpack -i2f -r -w -D -Y -q 4 '+outfile
endelse

if keyword_set(compress) then spawn,cmd


; close the images loop
endfor

print,'Total elapsed time (sec): ',systime(/seconds)-start_time

end