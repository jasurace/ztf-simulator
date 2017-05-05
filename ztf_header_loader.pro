; Prepare a header template
;
; ztf_header_loader,'hd1.csv','hd1.fits'
;
pro ztf_header_loader,infile,outfile,phdu=phdu

readcol,infile,name,comment,value,type,format='A,A,A,F',delimiter=','
ncards=n_elements(name)

if keyword_set(phdu) then begin
     mkhdr,hd
endif else begin
     dummy=randomn(seed,100,100)
     mkhdr,hd,dummy
endelse


for i=0,ncards-1 do begin

case 1 of
type[i] eq 0: print,name[i],value[i],comment[i]
type[i] eq 1: print,name[i],float(value[i]),comment[i]
type[i] eq 2: print,name[i],long(float(value[i])),comment[i]
type[i] eq 3: print,'COMMENT',comment[i]
endcase

case 1 of
type[i] eq 0: sxaddpar,hd,name[i],value[i],comment[i]
type[i] eq 1: sxaddpar,hd,name[i],float(value[i]),comment[i]
type[i] eq 2: sxaddpar,hd,name[i],long(float(value[i])),comment[i]
type[i] eq 3: sxaddpar,hd,' ',comment[i],after=name[i-1]
endcase

endfor

writefits,outfile,dummy,hd

end