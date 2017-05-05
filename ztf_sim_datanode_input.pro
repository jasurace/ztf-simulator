pro ztf_sim_datanode_input,infile,outbase,nodes

readcol,infile,filename,exposure,ccdid,mjd,fieldid,imtype,filter,telra,teldec,ccdra,ccddec,format='A,I,I,D,I,I,I,D,D,D,D'

fmt='(A40,I5,I4,F15.6,I12,I5,I5,F15.7,F12.7,F12.7,F12.7)'

npoints=n_elements(filename)

n=1+floor(npoints/nodes)
print,n,' files per node.'

i=0

outname3=strcompress(outbase+'_nodemaster.tcsh',/remove_all)
openw,3,outname3


for j=0,nodes-1 do begin

outname=strcompress(outbase+'_'+string(j+1)+'.list',/remove_all)
openw,1,outname

outname2=strcompress(outbase+'_'+string(j+1)+'.tcsh',/remove_all)
openw,2,outname2

if (j+1) lt 10 then begin
cmd='ssh '+strcompress('ztfjs@ztfops0'+string(j+1),/remove_all)+'.ipac.caltech.edu '+strcompress('idl/sim/'+outname2,/remove_all)
endif else begin
cmd='ssh '+strcompress('ztfjs@ztfops'+string(j+1),/remove_all)+'.ipac.caltech.edu '+strcompress('idl/sim/'+outname2,/remove_all)
endelse

printf,3,cmd

printf,2,'#!/usr/local/bin/tcsh'
printf,2,' '
printf,2,'cd idl/sim'
cmd='idl -e '+'"ztf_simdata_placepsf_v5,'+"'"+outname+"','/stage/ztf-test3/jason/current/',/compress,/ops"+'"'+" >& "+strcompress('node'+string(j+1)+'.out',/remove_all)+' &'
printf,2,cmd


for k=0,n-1 do begin


printf,1,format=fmt,filename[i],exposure[i],ccdid[i],mjd[i],fieldid[i],imtype[i],filter[i],telra[i],teldec[i],ccdra[i],ccddec[i]


i=i+1

if i gt npoints-1 then break

endfor

close,1,2

endfor

close,/all


cmd='chmod a+x node*.tcsh'
spawn,cmd


end