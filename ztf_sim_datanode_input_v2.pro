pro ztf_sim_datanode_input_v2,infile,outbase,outpath,nodenames

fmt='(A40,I5,I4,D18.10,I12,I5,I5,F15.7,F12.7,F12.7,F12.7)'

readcol,infile,filename,exposure,ccdid,mjd,fieldid,imtype,filter,telra,teldec,ccdra,ccddec,format='A,I,I,D,I,I,I,D,D,D,D'


nodes=n_elements(nodenames)

npoints=n_elements(filename)

n=1+floor(npoints/nodes)
print,n,' files per node.'

i=0

outname3=strcompress(outbase+'_nodemaster.csh',/remove_all)
openw,3,outname3


for j=0,nodes-1 do begin

outname=strcompress(outbase+'_'+string(nodenames[j])+'.list',/remove_all)
openw,1,outname

outname2=strcompress(outbase+'_'+string(nodenames[j])+'.csh',/remove_all)
openw,2,outname2

if nodenames[j] lt 10 then begin
cmd='ssh '+strcompress('ztfjs@ztfops0'+string(nodenames[j]),/remove_all)+'.ipac.caltech.edu '+outname2
endif else begin
cmd='ssh '+strcompress('ztfjs@ztfops'+string(nodenames[j]),/remove_all)+'.ipac.caltech.edu '+outname2
endelse

printf,3,cmd

printf,2,'#! /bin/csh'
printf,2,'cd idl/sim'
printf,2,'setenv LD_LIBRARY_PATH /ztf/ops/sw/stable/ext/lib:/ztf/ops/sw/160830/ext/lib'
cmd='/usr/local/exelis/idl85/bin/idl -e '+'"ztf_simdata_placepsf_v8,'+"'"+outname+"','"+outpath+"',/compress,/ops"+'"'+" >& "+strcompress(outbase+string(nodenames[j])+'.out',/remove_all)+' &'
printf,2,cmd


for k=0,n-1 do begin


printf,1,format=fmt,filename[i],exposure[i],ccdid[i],mjd[i],fieldid[i],imtype[i],filter[i],telra[i],teldec[i],ccdra[i],ccddec[i]


i=i+1

if i gt npoints-1 then break

endfor

close,1,2

endfor

close,/all

end
