function ztf_sim_saturation,ccd,satval

sat=where(ccd gt satval,nsat)

if (nsat gt 0) then begin
   ccd[sat]=satval
endif


return,ccd

end