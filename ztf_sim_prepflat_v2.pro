; Prepare a flatfield of the appropriate size
; 
;ztf_sim_prepflat,'PTF_rflat_c02.fits','ztf_flat.fits'
;
;
; v2 - changes to handle Frank's g-band flat. This is a much simpler
;        scheme that just applies a fixed value, does it in both
;        directions.
;
; v1 - used to make Rflat
;
pro ztf_sim_prepflat_v2,infile,outfile


; CCD FORMAT CONSTANTS
cw=6144.      
ch=6160.


in=readfits(infile,hd)
naxis1=sxpar(hd,'NAXIS1')
naxis2=sxpar(hd,'NAXIS2')

; edges of flat need trimming
in=in[10:naxis1-10,10:naxis2-10]
sz=size(in)
naxis1=sz[1]
naxis2=sz[2]
x=findgen(naxis1)

; flatten the image
;  this takes out gradients in the existing PTF flats
;
for i=0,naxis2-1 do begin
   in[*,i]=in[*,i]-median(in[*,i])
endfor
in=in+1

for i=0,naxis1-1 do begin
    in[i,*]=in[i,*]-median(in[i,*])
endfor
in=in+1



; figure out how to tile this
nx=floor(cw/naxis1)+1
ny=floor(ch/naxis2)+1

; make the output array
temp=fltarr(nx*naxis1,ny*naxis2)

for x=0,nx-1 do begin
  for y=0,ny-1 do begin
  
  print,x*naxis1,(x+1)*naxis1-1,y*naxis2,(y+1)*naxis2-1
  temp[x*naxis1:(x+1)*naxis1-1,y*naxis2:(y+1)*naxis2-1]=in
  
  
  endfor
endfor

out=temp[0:cw-1,0:ch-1]

writefits,outfile,out


end