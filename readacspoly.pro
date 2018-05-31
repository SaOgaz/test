; reads meancoeff.txt files
;+
; NAME:
;   readacspoly
; PURPOSE:   (one line only)
;    Read distortion solution and create IDC rows
;
; DESCRIPTION:
;   This program will output a text file that contains the IDC information in the 
;   IDC system. This file will be in to correct format to be read into the IRAF
;   task tcreate to create a tabular fits file.
;
;   At the moment, this program only works for f435w, f606w and f814w becuase 
;   of the filter keyword is hard coded at the moment and I need to add new 
;   logic to handle others. 
;
; CATEGORY:
; CALLING SEQUENCE:
;   readacspoly,filename,idcfile
;
; INPUTS:
;   filename - meancoeff or fincoeff file.
;
;   idcfile - an idc.txt files - contains columns for idc file.
;
; OPTIONAL INPUT PARAMETERS:
; KEYWORD INPUT PARAMETERS:
;   verbose    - if set will print to the screen.
;
;   acsfilters - what filter to put in the header of the idc.txt file. Defaults
;                to the directory that it is working in.
;
;   pre  - Tells if working on pre-SM04 data. The SIAF positions
;          of things changed at sm4 so need to know what the change was.
;
;   post - Tells if working on post-SM04 data. The SIAF positions
;          of things changed at sm4 so need to know what the change was.
;          assumes that it is working on data before 2011. If data is after 2011
;          then set the eleven keyword. if post and eleven are set, eleven will
;          override post.
;
;   eleven - Tells if working on post 2011 data. The SIAF positions changed in
;             2011 so it is important to get the correct date.if post and 
;             eleven are set, eleven will override post.
;          Do NOT use eleven
;
; OUTPUTS:
;   idcfile - an idc.txt files - contains columns for idc file.
;
; KEYWORD OUTPUT PARAMETERS:
; COMMON BLOCKS:
;
;   *** must have the buie library loaded!! ***
;   add /user/dborncamp/idl/buie/ to !path
;
; SIDE EFFECTS:
; RESTRICTIONS:
; PROCEDURE:
; MODIFICATION HISTORY:
;    December 5 2013 DMB - Adapted to ACS WFC - still a rough draft.
;    Feb 20 2014 DMB - Significantly changed calling sequence and 
;           implementation to allow it to be called for each filter, rather than
;	   be called for the entire filter set at once. Added documentation and 
;	   'smart' default for filter.
;    Mar 10 2014 DMB - Changed filters to be in correct slot.
;    Apr 1 2014 DMB - Added post keyword. The V2V3 system location changed 
;           from 2002 to 2011 so I need to account for this. This will now 
;           take these issues into account. Updated documentation.
;           The program may need to to be altered if creating an IDCTAB for 
;           before 2011. Right now the program only uses the 2011 V2V3ref which 
;           changed in 2002, 2009 and 2011. May want to put these values into
;           an input keyword. like /2009 & /2011 
;           uv2v2=> 2009 to 2011: 257.1520    ;after 2011: 257.3780
;           uv2v3=> ;2009 to 2011: 302.6620    ;after 2011: 302.5610
;   Apr 10 2014 DMB - added documentation to discription and some comments to the
;           code.
;   Apr 11 2014 DMB - added eleven keyword to handle the change in v2v3 SAIF 
;           aperatures.
;
;   May 14 2015 DMB - added capibility to use other filters and disabled the 
;           eleven keyword as it should not be used. It should handle most
;           filter combinations now, not just 3.
;
;-

PRO READACSPOLY, filename,idcfile,verbose=verbose,acsfilters=acsfilters,$
   post=POST,pre=pre;,eleven=eleven
self=' readacspoly '
if badpar(filename,7,0,caller=self+' filename ') then return 
if badpar(idcfile,7,0,caller=self+' idcfile ') then return 
if badpar(verbose,[0,1,2],0,caller=self+' verbose ',default=1) then return 
if badpar(acsfilters,[0,7],[0,1],caller=self+' acsfilter ',default= $
   [strupcase(strmid(filename,strpos(strlowcase(filename),'/f')+1,5))]) then return
;post is set by default as this is the most recent numbers published for the 
;V2V3 system.
if badpar(post,[0,1,2],0,caller=self+' post ',default=0) then return 
if badpar(pre,[0,1,2],0,caller=self+' pre ',default=0) then return
;if badpar(eleven,[0,1,2],0,caller=self+' eleven ',default=0) then return

if verbose then print,'readacspoly,'+filename+','+idcfile+',acsfilters='+acsfilters

;if acsfilters eq 'F606W' then begin
;   filter1='F606W'
;   filter2='CLEAR2L'
;endif else if acsfilters eq 'F435W' then begin
;   filter1='CLEAR1L'
;   filter2='F435W'
;endif else if acsfilters eq 'F814W' then begin
;   filter1='CLEAR1L'
;   filter2='F814W'
;endif else if acsfilters eq 'F775W' then begin
;   filter1='F775W'
;   filter2='CLEAR2L'
;endif

wheel1=['F555W','F775W','F625W','F550M','F850LP','POL0UV','POL60UV','POL120UV',$
        'F892N','F606W','F502N','G800L','F658N','F475W']
wheel2=['F660N','F814W','FR388N','FR423N','FR462N','F435W','FR656N','FR716N',$
        'FR782N','POL0V','F330W','POL60V','F250W','POL120V','PR200L','F344N',$
        'F220W','FR914M','FR853N','FR931N','FR459M','FR647M','FR1016N',$
        'FR505N','FR551N','FR601N']

;this will need to be smarter to determine the approperate clear filter
;meaning either clearS or clearL.
;works for now
z2=where(acsfilters[0] eq wheel2, count2)
z=where(acsfilters[0] eq wheel1, count)

if n_elements(count) + n_elements(count2) eq 0 then begin
    print,''
    print,'   *********  ++++++++++++++++  ***********'
    print,'There is a problem, the filter was not found in the filter wheel!'
    print,acsfilters
    print,''
    print,'   *********  ++++++++++++++++  ***********'
    print,''
    return
endif

if count gt 0 then begin
    filter1=acsfilters
    filter2='CLEAR2L'
endif else begin
    filter1='CLEAR1L'
    filter2=acsfilters
endelse
;help,acsfilters[0]
;print,count,filter1,filter2

if (not post) and (not pre) then begin ;and (not eleven) then begin
   print,'*** Need to set a date keyword! *** Try again'
   return
endif

if (post and pre) then begin ; or (eleven and pre) then begin
   print,'** Cannot have both post and pre data. try again'
   return
endif

if post then begin
   ;from WFC2 fix app from SIAF June 2011 in arc sec	
   uv2v2=257.1520 ;2009 to 2011: 257.1520    ;after 2011: 257.3780
   uv2v3=302.6620 ;2009 to 2011: 302.6620    ;after 2011: 302.5610
   ;uv2v2=257.3780 ;2009 to 2011: 257.1520    ;after 2011: 257.3780;
   ;uv2v3=302.5610 ;2009 to 2011: 302.6620    ;after 2011: 302.5610
endif

if pre then begin
   uv2v2=256.6020
   uv2v3=302.2520
endif

;if eleven then begin
;   uv2v2=257.3780 ;2009 to 2011: 257.1520    ;after 2011: 257.3780;
;   uv2v3=302.5610 ;2009 to 2011: 302.6620    ;after 2011: 302.5610
;endif

;;will need to change based on useafter date
;if post then begin 
;   uv2v2=257.3780 ;2009 to 2011: 257.1520    ;after 2011: 257.3780
;   uv2v3=302.5610 ;2009 to 2011: 302.6620    ;after 2011: 302.5610
;endif else begin
;   uv2v2=256.6020
;   uv2v3=302.2520
;endelse


order = 5
terms = (order+1)*(order+2)/2

;get the coefficients
skipline=0  ;;;these can change
firstline=2;skip the first 2 lines
header=2   ;# of lines between sets in txt file (acs1 and acs2)
readcol,filename,a1,b1,format='d,d',numline=terms,skipline=firstline,/silent,$
   count=count1
skipline=firstline+n_elements(a1)+header
readcol,filename,a2,b2,format='d,d',numline=terms,skipline=skipline,/silent,$
   count=count2

;make sure the correct number of things were read in
if (count1 ne terms) or (count2 ne terms) then begin
   print,'check read-in columns and skip lines'
   print,'count1: ',count1
   print,'count2: ',count2
   print,'terms: ',terms
   return
endif   

if verbose then print,'a1, b1 '
if verbose then for i=0,n_elements(a1)-1 do print,a1[i],b1[i]

if verbose then print
if verbose then print,'a2, b2'
if verbose then for i=0,n_elements(a2)-1 do print,a2[i],b2[i]
;forprint,a2,b2

if verbose then PRINT, 'Reference points'
if verbose then PRINT, a1[0], b1[0]
v21 = a1[0]
v31 = b1[0]

if verbose then PRINT, a2[0], b2[0]
v22 = a2[0]
v32 = b2[0]

; Some derived quantities
x1scale = SQRT(a1[2]^2+b1[2]^2) ;chip one
y1scale = SQRT(a1[1]^2+b1[1]^2)
betax1 = ATAN(a1[2],b1[2])  ;should be small ~ 3 degrees, unless SIAF changes
betay1 = ATAN(a1[1], b1[1])

x2scale = SQRT(a2[2]^2+b2[2]^2) ;chip two
y2scale = SQRT(a2[1]^2+b2[1]^2)
betax2 = ATAN(a2[2],b2[2])
betay2 = ATAN(a2[1], b2[1])

;acsfilters=['F606W']

;create formats for later
form1 = "('1  FORWARD  ', A10, A10, 2I8, 2F10.2, F10.4, F10.5, 2F12.6)"
form2 = "('2  FORWARD  ', A10, A10, 2I8, 2F10.2, F10.4, F10.5, 2F12.6)"

if verbose then PRINT, '           X-scale    Y-scale          Beta-x            Beta-y       Beta-y - Beta-x'
if verbose then PRINT, x1scale, y1scale, betax1*!radeg, betay1*!radeg, (betay1-betax1)*!radeg   
if verbose then PRINT, x2scale, y2scale, betax2*!radeg, betay2*!radeg, (betay2-betax2)*!radeg 

v21 = a1[0]-a2[0] +uv2v2
v31 = b1[0]-b2[0] +uv2v3
v22 = uv2v2
v32 = uv2v3
if verbose then PRINT, 'New V-values', v21, v31, v22, v32
;IDC table output - Drizzle reference frame
;theta for WFC is anti parallel to v3 so theta 180
theta = 180.0 ; ???? Have to be chekc with Colin Cox - correct

;ad1 = (-a1+b1);/SQRT(2.0)
;bd1 = ( a1+b1);/SQRT(2.0)
;ad2 = (-a2+b2);/SQRT(2.0)
;bd2 = ( a2+b2);/SQRT(2.0)

;The y axis is flipped relative to V3
ad1 = a1   ;x in chip1
bd1 = -b1  ;y in chip1
ad2 = a2   ;x in chip2
bd2 = -b2  ;y in chip2


xsize = 4096
ysize = 2048
xref = 2048.0
yref = 1024.0
scale = 0.050 ;??????have to be check with Colin Cox - correct
;the plate scale should be 0.05, even though will not be exact
 
OPENW, idc, idcfile, width=400, /GET_LUN
if verbose then PRINT
nfilt = N_ELEMENTS(acsfilters)
FOR f = 0, nfilt-1 DO BEGIN
    ;PRINT,  acsfilters[f], xsize, ysize, xref, yref, theta, scale, v21, v31, FORMAT = form1
    PRINTF, idc, filter1, filter2, xsize, ysize, xref, yref, v21, v31,scale, FORMAT = form1      
    PRINTF, idc, ad1[1:terms-1]
    PRINTF, idc, bd1[1:terms-1]
    PRINTF, idc, filter1, filter2, xsize, ysize, xref, yref, v22, v32,scale, FORMAT = form2
    ;PRINT,  acsfilters[f], xsize, ysize, xref, yref, theta, scale, v22, v32, FORMAT = form2
    PRINTF, idc, ad2[1:terms-1]
    PRINTF, idc, bd2[1:terms-1]
ENDFOR     

FREE_LUN, idc
PRINT, 'Data written to:  ', idcfile 

END
