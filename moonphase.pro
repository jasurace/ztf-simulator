function moonphase,jd

; initialize the new moon data
;  phase was exactly zero at this time.
;http://aa.usno.navy.mil/cgi-bin/aa_phases.pl?year=2010&month=1&day=1&nump=50&format=t

jd0=2455211.7993D
lm = 29.530587981 ; synodic month duration in days

phase=(jd-jd0)/lm
phase=phase-floor(phase)
phase=phase*360.

return,phase

end