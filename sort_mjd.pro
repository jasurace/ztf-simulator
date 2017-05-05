pro sort_mjd,infile,outfile

readcol,infile,ra,dec,fid,filter,imtype,mjd,format='D,D,I,I,I,D'
fmt='(F12.7,F12.7,I8,I5,I5,D16.8)'

nexp=n_elements(ra)

key=sort(mjd)

openw,1,outfile

for i=0,nexp-1 do begin

printf,1,format=fmt,ra[key[i]],dec[key[i]],fid[key[i]],filter[key[i]],imtype[key[i]],mjd[key[i]]

endfor

close,/all



end