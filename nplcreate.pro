;+
; Program to create necessary npolfiles for Distortion Solution
;
; This assumes that there is only one NPOLFILE for each filter and its clear
; counterpart.
;
;-

verbose=1
odir='/grp/hst/acs/dborncamp/deliver/forMatt/'
indir='/grp/hst/acs/dborncamp/deliver/'

f606file='acs_f606w_270115_v3npol.fits'
f435file='acs_f435w_031015_npol.fits'
f814file='acs_f814w_022515_npol.fits'
f475file='acs_f475w_220415_npol.fits'
f625file='acs_f625w_180615_npol.fits'
f775file='acs_f775w_031115_npol.fits'
f555file='acs_f555w_051115_npol.fits'
f658file='acs_f658n_051115.npol.fits'
f502file='acs_f502n_012716_npol.fits'
f850file='acs_f850lp_020116_npol.fits'

print,' *** Reminder: Add new known NPL files to the case statement. ***'

;readcol,'/grp/hst/acs/dborncamp/allfilters.txt',filter1,filter2,$
;    count=numfilters,format='a,a',/silent,comment='#'
;all possible combinations from the template file
;filter1=['CLEAR1L','F555W','F775W','F625W','F550M','F850LP',$
;         'CLEAR1S','POL0UV','POL60UV','POL120UV',$
;         'F892N','F606W','F502N','G800L','F658N','F475W',$
;         'F122M','F115LP','F125LP','F140LP','F150LP',$
;         'F165LP','PR110L','PR130L','BLOCK1','BLOCK2',$
;         'BLOCK3','BLOCK4','N/A','ANY']
;
;filter2=['CLEAR2L','F660N','F814W','FR388N','FR423N',$
;         'FR462N','F435W','FR656N','FR716N','FR782N',$
;         'CLEAR2S','POL0V','F330W','POL60V','F250W',$
;         'POL120V','PR200L','F344N','F220W','FR914M',$
;         'FR853N','FR931N','FR459M','FR647M','FR1016N',$
;         'FR505N','FR551N','FR601N','N/A','ANY']

readcol,'/grp/hst/acs/dborncamp/active_nplfiles.txt',nplfiles,count=numfilters,$
    format='a',/silent,comment='#'

filter1=strarr(numfilters)
filter2=strarr(numfilters)

for i=0,numfilters-1 do begin
    hdr=headfits(nplfiles[i],/silent)
    filter1[i]=strtrim(sxpar(hdr,'FILTER1',/silent))
    filter2[i]=strtrim(sxpar(hdr,'FILTER2',/silent))
endfor
stop
if verbose then print,'working on:'
if verbose then print,'Filter1','Filter2','Reffile','Outfile',form=$
    '(2a9,a25,a40)'

for i=0,numfilters-1 do begin
    ;reset the history
   hist=[$
     ' ',$
     ' After applying the pixel grid irrgularity correction and',$
     ' best-fitting polynomial, the residuals of the X and Y',$
     ' positions between the observed 47Tuc ACS/WFC F606W filter and',$
     ' X and Y positions from the standard astrometric catalog',$
     ' (ACS ISR 2015-06) have shown fine-scale residual',$
     ' structure at the level of 0.05 pixels. To remove the fine-scale',$
     ' variations 2-D look-up table has been been created, which is linearly',$
     ' interpolated at any point in the ACS/WFC images. ',$
     ' The astrometric errors due to the fine-scale filter induced distortion',$
     ' have been corrected down to the level of ~0.02 pixels in the',$
     ' calibrated filters.',$
     ' ',$
     ' The correction is stored as an image extension with one row',$
     ' in X and one column in Y. Each element in the row/column ',$
     ' specifies the correction in pixels for every pixels in the column ',$
     ' (or row) in science extension.',$
     ' For ACS/WFC, the correction is in X and Y directions for each WFC CCD',$
     ' chip.',$
     ' ']

    case 1 OF
        ;filter2 first
        (filter2[i] eq 'F814W'): begin
            reffile=f814file
            end ;of 814
        (filter2[i] eq 'F435W'): begin
            reffile=f435file
            end ;of 435
        ;filter1 next
        (filter1[i] eq 'F475W'): begin
            reffile=f475file
            end
        (filter1[i] eq 'F625W'): begin
            reffile=f625file
            end
        (filter1[i] eq 'F775W'): begin
            reffile=f775file
            end
        (filter1[i] eq 'F555W'): begin
            reffile=f555file
            end
        (filter1[i] eq 'F658N'): begin
            reffile=f658file
            end
        (filter1[i] eq 'F502N'): begin
            reffile=f502file
            end
        (filter1[i] eq 'F850LP'): begin
            reffile=f850file
            end
        else: begin
            reffile=f606file
;            hist=[hist,$
;          ' Non-polynomial offset file generated from '+reffile,$
;          ' This is only added to the flt.fits file and used in coordinate',$
;          ' transformations if the npol reference filename is specified in',$
;          ' the header.  The offsets are copied from the reference file into',$
;          ' two arrays for each chip.  Each array is stored as a 64x32 pixel',$
;          ' image that gets interpolated up to the full chip size.  Two new',$
;          ' extensions for each chip are also appended to the flt file',$
;          ' (WCSDVARR) when it is used.',$
;          '',$
;          ' This file contains the Non-polynomial offset for the ACS/WFC',$ 
;          ' channel. It contains the same solution as F606W as it is the best',$
;          ' calibrated and the remaining filters have not yet been ',$
;          ' calibrated to the same level of detail.',$
;          ' This should change in the near future.',$
;          ' ']
          hist=[hist,$
          ' ',$
;          ' Non-polynomial offset file generated from '+reffile,$
;          ' ',$
          ' This file contains the Non-polynomial offset for the ACS/WFC',$ 
          ' channel. It contains the same solution as F606W as it is the best',$
          ' calibrated and the remaining filters have not yet been ',$
          ' calibrated to the same level of detail.',$
          ' This may change in the near future as calibrations become',$
          ' available',$
          ' ']
            end ;of else
    endcase
    
    ;special case
    ;if filter1[i] eq 'F606W' then hist=strarr(1)

    hist=[hist,$
    ' Non-polynomial offset file generated from '+reffile,$
    ' This is only added to the flt.fits file and used in coordinate',$
    ' transformations if the npol reference filename is specified in',$
    ' the header.  The offsets are copied from the reference file into',$
    ' two arrays for each chip.  Each array is stored as a 64x32 pixel',$
    ' image that gets interpolated up to the full chip size.  Two new',$
    ' extensions for each chip are also appended to the flt file',$
    ' (WCSDVARR) when it is used.',$
    ' ',$
    ' This solution does not change with time, but is filter dependent',$
    ' ',$
    ' File origionally named: '+reffile]
    

    file='wfc_update6_'+filter1[i]+'_'+filter2[i]+'_npl.fits' 
    ;special case
    if filter2[i] eq 'N/A' then file='acs_'+filter1[i]+'_'+'N-A'+'_npl.fits'

    if verbose then print,filter1[i],filter2[i],reffile,file,form='(2a9,2a40)'
    

    if exists(odir+file) then begin
        file_delete,odir+file 
    endif

    ;get headers
    hdr=headfits(indir+reffile,/silent)
    npl1=mrdfits(indir+reffile,1,hdr1,/silent)
    npl2=mrdfits(indir+reffile,2,hdr2,/silent)
    npl3=mrdfits(indir+reffile,3,hdr3,/silent)
    npl4=mrdfits(indir+reffile,4,hdr4,/silent)

    ;change headers
    ;delete things
    sxdelpar,hdr,'FILTER'
    sxdelpar,hdr,'IRAF-TLM'
    ;add things
    sxaddpar,hdr,'DATE',systime()
    sxaddpar,hdr,'NEXTEND',4,'Number of standard extensions '
    sxaddpar,hdr,'FILENAME',file,'Name of file'
    sxaddpar,hdr,'FILETYPE','DXY GRID','Type of data found in data file'
    sxaddpar,hdr,'OBSTYPE','IMAGING ','Type of observation '
    sxaddpar,hdr,'FILTER1',filter1[i],'Element selected from filter wheel 1'
    sxaddpar,hdr,'FILTER2',filter2[i],'Element selected from filter wheel 2'
    sxaddpar,hdr,'USEAFTER','Mar 01 2002 00:00:00'
    sxaddpar,hdr,'DESCRIP','Non-polynomial filter dependent distortion file for ACS/WFC--------'
    sxaddpar,hdr,'PEDIGREE','INFLIGHT 11/11/2002'
    sxaddpar,hdr,'COMMENT','Original NPOLFILE derivation by V.Kozhurina-Platais'
    sxaddpar,hdr,'COMMENT','NPOL header updated by D. Borncamp 15 Jan 2016'
    ;add history
    sxaddhist,hist,hdr

    ;add other extension header
    ;there should be an easier way to do this...
    sxaddpar,hdr1,'INHERIT','F','Inherits global header'
    sxaddpar,hdr1,'WCSDIM',2
    sxaddpar,hdr1,'WAT0_001','system=physical'
    sxaddpar,hdr1,'WAT1_001','wtype=linear','Coordinate increment along axis'
    sxaddpar,hdr1,'WAT2_001','wtype=linear','Coordinate increment along axis'

    sxaddpar,hdr2,'INHERIT','F','Inherits global header'
    sxaddpar,hdr2,'WCSDIM',2
    sxaddpar,hdr2,'WAT0_001','system=physical'
    sxaddpar,hdr2,'WAT1_001','wtype=linear','Coordinate increment along axis'
    sxaddpar,hdr2,'WAT2_001','wtype=linear','Coordinate increment along axis'

    sxaddpar,hdr3,'INHERIT','F','Inherits global header'
    sxaddpar,hdr3,'WCSDIM',2
    sxaddpar,hdr3,'WAT0_001','system=physical'
    sxaddpar,hdr3,'WAT1_001','wtype=linear','Coordinate increment along axis'
    sxaddpar,hdr3,'WAT2_001','wtype=linear','Coordinate increment along axis'
    
    sxaddpar,hdr4,'INHERIT','F','Inherits global header'
    sxaddpar,hdr4,'WCSDIM',2
    sxaddpar,hdr4,'WAT0_001','system=physical'
    sxaddpar,hdr4,'WAT1_001','wtype=linear','Coordinate increment along axis'
    sxaddpar,hdr4,'WAT2_001','wtype=linear','Coordinate increment along axis'    
    
    file=odir+file
    ;write file
    mwrfits,0,file,hdr
    mwrfits,npl1,file,hdr1,/silent
    mwrfits,npl2,file,hdr2,/silent
    mwrfits,npl3,file,hdr3,/silent
    mwrfits,npl4,file,hdr4,/silent
endfor


end
