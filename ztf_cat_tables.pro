pro ztf_cat_tables

; start with the transient table

files=file_search('ztf_*transient.tbl')
nfiles=n_elements(files)

for i=0l,nfiles-1 do begin

if file_test(files[i],/zero_length) ne 1 then begin

readcol,files[i],ra0,dec0,x0,y0,mag0,ttype0,format='D,D,I,I,D,I',/silent

sz=size(ra)
fileindex0=findgen(n_elements(ra0))
fileindex0[*]=i

if (sz[0] eq 0) then begin
   ra=ra0
   dec=dec0
   x=x0
   y=y0
   mag=mag0
   ttype=ttype0
   fileindex=fileindex0
endif else begin
   ra=[ra,ra0]
   dec=[dec,dec0]
   x=[x,x0]
   y=[y,y0]
   mag=[mag,mag0]
   ttype=[ttype,ttype0]
   fileindex=[fileindex,fileindex0]
endelse

endif

endfor

radhits=where(ttype eq 1,nradhits)
sn=where(ttype eq 0,nsne)
fmt='(A42,D15.6,D13.6,D12.3)'

openw,unit,'radhit_summary.tbl',/get_lun

for i=0l,nradhits-1 do begin

filename=strcompress(strmid(files[fileindex[radhits[i]]],0,strlen(files[fileindex[radhits[i]]])-14)+'.fits.fz')
printf,unit,format=fmt,filename,ra[radhits[i]],dec[radhits[i]],mag[radhits[i]]

endfor

close,/all


openw,unit,'transient_summary.tbl',/get_lun

for i=0l,nsne-1 do begin

filename=strcompress(strmid(files[fileindex[sn[i]]],0,strlen(files[fileindex[sn[i]]])-14)+'.fits.fz')
printf,unit,format=fmt,filename,ra[sn[i]],dec[sn[i]],mag[sn[i]]

endfor

close,/all


; short streak table

files=file_search('ztf_*shortstreak.tbl')
nfiles=n_elements(files)
firstpass=1

for i=0l,nfiles-1 do begin

readcol,files[i],mag0,ra0,dec0,length0,pa0,format='D,D,D,I,D',/silent

fileindex0=findgen(n_elements(ra0))
fileindex0[*]=i

if (firstpass eq 1) then begin
   ra=ra0
   dec=dec0
   mag=mag0
   fileindex=fileindex0
   length=length0
   pa=pa0
   firstpass=0
endif else begin
   ra=[ra,ra0]
   dec=[dec,dec0]
   mag=[mag,mag0]
   fileindex=[fileindex,fileindex0]
   length=[length,length0]
   pa=[pa,pa0]
endelse

endfor

openw,unit,'shortstreak_summary.tbl',/get_lun

fmt='(A42,D15.6,D13.6,D13.6,I8,D12.5)'

for i=0l,n_elements(ra)-1 do begin
filename=strcompress(strmid(files[fileindex[i]],0,strlen(files[fileindex[i]])-16)+'.fits.fz')
    printf,unit,format=fmt,filename,ra[i],dec[i],mag[i],length[i],pa[i]
endfor
close,/all



end