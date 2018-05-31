;+
; NAME:
;   veraacscoeff
; PURPOSE:   (one line only)
;   To calculate scale and beta in V2V3 system and reorginize output files for next step.
;
; DESCRIPTION:
;   This program will calculate the scale and beta in the V2V3 coordinate system
;   for the chip that it was given. It will ingest mcoeff or meancoeff files 
;   that are produced by coeff2v23.pro. It will also output some files that 
;   contain a lot of information about the coefficients.
;
; CATEGORY:
; CALLING SEQUENCE:
;   veraacscoeff,chipfile,chipnumber
;
; INPUTS:
;   chipfile   - The meancoeff or mcoeff file created by coeft2v23.pro
;
;   chipnumber - The chip number to process (NOT the extenstion!!) 
;
; OPTIONAL INPUT PARAMETERS:
; KEYWORD INPUT PARAMETERS:
;   verbose   - if set will print to the screen.
;
; OUTPUTS:
;   <chipfile>.info - This has the basic info for the theta on this filter.
;                     it includes all of the angles and some information 
;		      on the rotation of the coeffcients.
;
;   <chipfile>.txt  - This is the coefficients within the V2V3 system.
; KEYWORD OUTPUT PARAMETERS:
; COMMON BLOCKS:
;   *** must have the buie library loaded!! ***
;   add /user/dborncamp/idl/buie/ to !path
;
; SIDE EFFECTS:
; RESTRICTIONS:
; PROCEDURE:
; MODIFICATION HISTORY:
;   Feb 20 2014 DMB - Hevily modified implementation and calling sequence. 
;                    This now works for ACS insead of WFC3. The alogrothim for 
;		     transforming coefficients has not changed, when changing 
;		     instruments.
;-

PRO VERAACSCOEFF, chipfile, chipnumber,verbose=VERBOSE
; chipnumber is 1, 2, meaning chips WFC1 or WFC2 not exten
self=' veraacscoeff '
if badpar(chipfile,7,0,caller=self+' chipfile ') then return 
if badpar(chipnumber,[1,2,3],0,caller=self+' ext_search ') then return 
if badpar(verbose,[0,1,2],0,caller=self+' verbose ',default=1) then return 

;get a good place to write things. and make a good name
;is specified in chipfile
;if strpos(chipfile,'/') eq -1 th,1]en begin
;   outfile=strmid(chipfile,$
;      strpos(chipfile,'/',/reverse_search)+1,100)+'.txt' 
;   outfile2=outdir+'/'+strmid(chipfile,$
;      strpos(chipfile,'/',/reverse_search)+1,100)+'.info' 
   outfile=chipfile+'.txt'
   outfile2=chipfile+'.info'
;endif

detector=STRING(chipnumber, FORMAT='(" WFC",I1)')

order=5
terms = (order+1)*(order+2)/2
va = DBLARR(terms)
vb= DBLARR(terms)
a = DBLARR(order+1,order+1)
b = DBLARR(order+1,order+1)
da = DBLARR(order+1,order+1)
db = DBLARR(order+1,order+1)

if verbose then PRINT, chipfile
if verbose then PRINT, 'INPUT'

;n=dummy variable, Don't care about those columns
readcol,chipfile,n,va,n,n,vb,n,format='i,d,d,i,d,d',/silent

; Place coeffs in i,j layout
k=0
FOR i = 0, order DO $
   FOR j = 0, i DO BEGIN
	a[i,i-j] = va[k]
	b[i,i-j] = vb[k]
	k++
   ENDFOR

;a and b are order by order arrays with the lower left diagonal part empty
;for acs the pixel size should be 0.05, allows conversion to arcsec
IF (chipnumber eq 1) or (chipnumber eq 2) THEN pix = 0.05

a = a*pix
b = b*pix
if verbose then PRINT,a
if verbose then PRINT,b

;get scale
xscale = SQRT(a[1,1]^2+b[1,1]^2)
yscale = SQRT(a[1,0]^2+b[1,0]^2)
if verbose then PRINT, 'X scale', xscale
if verbose then PRINT, 'Y scale', yscale
betax = ATAN(a[1,1], b[1,1])/!DTOR
betay = ATAN(a[1,0], b[1,0])/!DTOR
if verbose then PRINT, 'betax', betax
if verbose then PRINT, 'betay', betay
if verbose then PRINT, 'Opening angle',betay-betax

;if verbose then PRINT
if verbose then PRINT, ' REORDERED AND SCALED '
;if verbose then PRINT
if verbose then print,outfile
if exists(outfile) then file_delete,outfile

if verbose then PRINT, chipfile, detector
;write things to new file. contains all coefficients
OPENW, out, outfile, /GET_LUN
printf,out,systime()
PRINTF, out, chipfile, detector

;a small ascii file that has the computed info at a glance
fmt='(a13,d18.12)'
openw,out2,outfile2,/get_lun
printf,out2,systime()
PRINTf,out2, 'X scale', xscale,format=fmt
PRINTf,out2, 'Y scale', yscale,format=fmt
PRINTf,out2, 'betax', betax,format=fmt
PRINTf,out2, 'betay', betay,format=fmt
PRINTf,out2, 'Opening angle',betay-betax,format=fmt

la = DBLARR(terms)
lb = DBLARR(terms)
k=0
FOR i = 0, order DO $
   FOR j = 0, i DO BEGIN
	la[k] = a[i,j]
	lb[k] = b[i,j]
	if verbose then PRINT, la[k], lb[k]
	PRINTF, out, la[k], lb[k],format='(2E20.12)'
	k++
   ENDFOR
FREE_LUN, out,out2

if verbose then PRINT, la, FORMAT='(F10.4, 2F12.6, 12E14.5)'
if verbose then PRINT, lb, FORMAT='(F10.4, 2F12.6, 12E14.5)'

END
