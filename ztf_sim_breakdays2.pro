pro ztf_sim_breakdays2

; read in eric's file
readcol,'frank_summer.txt',ra,dec,fid,filt,imtype,mjd,format='d,d,i,a,i,d'
nobs=n_elements(ra)
 mjd=mjd+17.

; first night name
night=18

; this is the output format
;fmt='(F12.5,F12.5,I12,I5,I5,F25.10)'
fmt='(F12.7,F12.7,I8,I5,I5,D16.8)'

; remake the filter type
ifilt=intarr(nobs)
ifilt[where(filt eq 'g')]=1
ifilt[where(filt eq 'r')]=2

for i=0,nobs-1 do begin

if i eq 0 then begin
    outfile=strcompress('night'+string(night)+'_sci.list',/remove_all)
    openw,unit,outfile,/get_lun
    printf,unit,format=fmt,ra[i],dec[i],fid[i],ifilt[i],imtype[i],mjd[i]
endif else begin

if (mjd[i]-mjd[i-1]) gt (1/24.) then begin
    close,/all   
    night=night+1
    outfile=strcompress('night'+string(night)+'_sci.list',/remove_all)
    openw,unit,outfile,/get_lun
    printf,unit,format=fmt,ra[i],dec[i],fid[i],ifilt[i],imtype[i],mjd[i]
endif else begin
    printf,unit,format=fmt,ra[i],dec[i],fid[i],ifilt[i],imtype[i],mjd[i]
endelse
endelse

endfor

close,/all


; we have now made the individual night observation files
;  now make the sims
for night=18,34 do begin

      infile=strcompress('night'+string(night)+'_sci.list',/remove_all)
      readcol,infile,ra,dec,fid,filt,imtype,mjd,format='d,d,i,a,i,d'
      
      outfile=strcompress('night'+string(night)+'_sim.list',/remove_all)
      ztf_makesims_v2,outfile,mjd[0]

endfor


; now let's concatenate these things all together
for night=18,34 do begin

infile2=strcompress('night'+string(night)+'_sci.list',/remove_all)
infile=strcompress('night'+string(night)+'_sim.list',/remove_all)
outfile=strcompress('night'+string(night)+'_allobs.list',/remove_all)

cmd='cat '+infile+' '+infile2+' > '+outfile
spawn,cmd


endfor


; now let's make the expansion files
for night=18,34 do begin

infile=strcompress('night'+string(night)+'_allobs.list',/remove_all)
outfile=strcompress('night'+string(night)+'_allobs_expansion.list',/remove_all)

ztf_simdata_datacenters,infile,outfile,/pretimed

endfor







end