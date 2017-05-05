;
; Add a model sky background
;
function ztf_sim_skybackground,in,magzp,band


; dark sky background from Abe
case band of 
1: dark_background=10^((21.1-magzp)/(-2.5))
2: dark_background=10^((20.9-magzp)/(-2.5))
3: dark_background=10^((19.2-magzp)/(-2.5))
else: dark_background=10^((20.9-magzp)/(-2.5))
endcase

out=in+dark_background 


return,out

end

;http://lcogt.net/user/apickles/dev/Palomar/SkyBright/Aube.html
;Filter       U     B     V     Rc    Ic   |   u'    g'    r'    i'    z'
;λcentral(Å)  3640  4400  5470  6490  8020  |  3550  4670  6160  7470  8920
;mag/arcsec2 20.6  21.1  20.5  19.9  19.2  |  20.5  20.9  20.1  19.4  18.9 

