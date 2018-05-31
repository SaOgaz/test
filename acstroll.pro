;In the function below, roll0 is PA_V3, dec0 is the declination where you are pointing.
;V2,V3  is your aperture reference point.
;Inputs and outputs are in degrees except for v2v3 which is in arcsec.
;This is modifyed version from Colin Cox, february 12, 2010.
;
;pro TROLL,dec0,roll0
;;;Dec0 and roll0 are from f160w.dec.info, where roll0 is PA_V3 from
;;;the header and pasted roll0_cor into 
;
; Given roll0 at V1 axis pointing to (ra0 dec0) calculate roll at v2, v3
; Angles in degrees except v2,v3 in arcsec
;
;openw,1,'orientat_pav3_allangle.stat'
;readcol,'f160w.dec.info',infile,ra0,dec0,p1,p2,roll1,roll0,a,exp,vafactor,$
;          form='(a,d,d,f,f,d,d,a,f,d)'
;+
; NAME:
;   acstroll
;
; PURPOSE:   (one line only)
;   Calculate the real roll angle of HST relative to V2V3
;
; DESCRIPTION:
;   This function returns the roll angle of the spot on the v2v3 frame that 
;   the instrument sits. It uses a lot of complicated sphereical to derive this 
;   position.
;
;   See ACS TIR for help with definition of math.
;
;   make sure to keep track of the date, the aperature files changed and the
;   keywords need to be correct here.
;
;   a date keyword must be chosen!
;
; CATEGORY:
;   Calibration
;
; CALLING SEQUENCE:
;   ep=acstroll(dec0,roll0)
;
; INPUTS:
;   dec0   - declination of target of telescope.
;
;   roll0  - roll angle of the telescope. Equal to PA_V3 in the header.
;
; OPTIONAL INPUT PARAMETERS:
; KEYWORD INPUT PARAMETERS:
;   pre  - Tells if working on pre-SM04 data. The SIAF positions
;          of things changed at sm4 so need to know what the change was.
;
;   post - Tells if working on post-SM04 data. The SIAF positions
;          of things changed at sm4 so need to know what the change was.
;          assumes that it is working on data before 2011. If data is after 2011
;          then set the eleven keyword. if post and eleven are set, eleven will
;          override post.
;
;    eleven - Tells if working on post 2011 data. The SIAF positions changed in
;              2011 so it is important to get the correct date.if post and 
;              eleven are set, eleven will override post.
;           Do NOT use eleven!
;
;
; OUTPUTS:
;   roll - roll of the telescope in degrees. returns -1 if error occured.
;
; KEYWORD OUTPUT PARAMETERS:
; COMMON BLOCKS:
; SIDE EFFECTS:
; RESTRICTIONS:
; PROCEDURE:
; MODIFICATION HISTORY:
;   Dec 05 2013 DMB - Inherated from Vera P who inherated it from Colin C. I 
;                made it into a function and cleaned up a lot of the code. I
;                do not fully understand the trig in this funciton, but it sems
;                to work.
;   Apr 09 2014 DMB - Cleaned up the code, added post keyword and added more 
;                documentation.
;
;-

function acstroll,dec0,roll0,post=post,pre=pre;,eleven=eleven
self='acstroll'
if badpar(dec0,[1,2,3,4,5],0,caller=self+' dec0 ') then return,-1 
if badpar(roll0,[1,2,3,4,5],0,caller=self+' roll0 ') then return,-1 
if badpar(post,[0,1,2],0,caller=self+' post ',default=0) then return,-1 
if badpar(pre,[0,1,2],0,caller=self+' pre ',default=0) then return,-1 
;if badpar(eleven,[0,1,2],0,caller=self+' eleven ',default=0) then return,-1 

if (not post) and (not pre) then begin ;and (not eleven) then begin
   print,'*** Need to set a date keyword! *** Try again'
   return,-1
endif

if post and pre then begin
   print,'** Cannot have both post and pre data. try again'
   return,-1
endif

if post then begin
   ;from WFC2 fix app from SIAF June 2011 in arc sec	
   v2=257.1520 ;2009 to 2011: 257.1520    ;after 2011: 257.3780;
   v3=302.6620 ;2009 to 2011: 302.6620    ;after 2011: 302.5610
endif

if pre then begin
   v2=256.6020
   v3=302.2520
endif

;if eleven then begin
;   v2=257.3780 ;2009 to 2011: 257.1520    ;after 2011: 257.3780;
;   v3=302.5610 ;2009 to 2011: 302.6620    ;after 2011: 302.5610
;endif

v2rad = v2*!DTOR/3.6D03  ; Convert from arcseconds to radians
v3rad = v3*!DTOR/3.6D03  ; and force double precision

;find rho, see ACS TIR 14-02
sinrhosq = sin(v2rad)^2 + sin(v3rad)^2 - sin(v2rad)^2*sin(v3rad)^2

IF sinrhosq GT 0.0 THEN BEGIN
   sinrho = SQRT(sinrhosq)         ;y in radians
   cosrho = SQRT(1.0D0 - sinrhosq) ;x in radians
   beta = ASIN(sin(v3rad)/sinrho)
   gamma = ASIN(sin(v2rad)/sinrho)

;   IF v2 lt 0.0 THEN beta = !PI - beta ; keep for other instruments
;   IF v3 lt 0.0 THEN gamma = !PI - gamma ; keep for other instruments

   a = !PI/2 + roll0*!DTOR - beta
   b = ATAN(sin(a)*cos(dec0*!DTOR), sin(dec0*!DTOR)*sinrho-cos(dec0*!DTOR)*cosrho*cos(a))
   roll = !PI-(gamma + b)

   IF roll lt 0.0 THEN roll = roll + 2*!pi ; Keep between +/- pi
 
   roll = roll/!DTOR ; Result in degrees

endif else begin
   roll = roll0
   print,"sinrhsq less than 0, returning roll0"
endelse

;print,roll
;printf,1,infile,ra0,dec0,roll0,roll1,roll,exp,vafactor,$
;          form='(a,d,d,d,d,d,f,d)'

RETURN, roll

END
