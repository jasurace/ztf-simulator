; Chip offsets from center in pixels
;
; ccd is 0-15
;
; We THINK the orientation is
;
;
;NE
;   12 13 14 15
;   08 09 10 11
;   04 05 06 07
;   00 01 02 03
;
function ztf_getchipoffsets,ccdid,$
                            center=center
                            
                            

ccdnsgap=13.*60. ; as per Rich Dekany 1/26/15
ccdewgap=10.*60.
width=6144.      ; CCD format (updated 4/4/16)
height=6160.

posx=[2,1,-1,-2, $
      2,1,-1,-2, $
      2,1,-1,-2, $
      2,1,-1,-2]
     
posy=[2,2,2,2, $
      1,1,1,1, $
     -1,-1,-1,-1, $
     -2,-2,-2,-2]
      


x=signum(posx[ccdid])*0.5*ccdewgap + $ ; center gap
  signum(posx[ccdid])*(abs(posx[ccdid])-1)*ccdewgap + $
  posx[ccdid]*width ; 

y=signum(posy[ccdid])*0.5*ccdnsgap + $
  signum(posy[ccdid])*(abs(posy[ccdid])-1)*ccdnsgap + $
  posy[ccdid]*height
  

x=x+(width/2.)*(-1.)*signum(posx[ccdid])
y=y+(height/2.)*(-1.)*signum(posy[ccdid])

if (keyword_set(center) ne 1)then begin
  x=x+width/2.
  y=y+width/2.
endif
   


return,[x,y]

end


