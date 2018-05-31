;**add /user/dborncamp/idl/buie/ to !path
;+
; NAME: 
;   imcomatch
;
; PURPOSE:   (one line only)
;   Match up Vera's coefficient files and perform roll calculations.
;
; DESCRIPTION:
;    
;    This is the first step in creating an IDC table from coefficients. It will
;    match up the coefficient files with things found in the angle.stat file.
;    It will also filter out bad frames from the fit if found in the badframes 
;    file.
;
; CATEGORY:
;   Distortion
;
; CALLING SEQUENCE:
;   imcomatch,cdir,idir,prefix
;
; INPUTS:
;   cdir    - Directory that contains .coeff files.
;   idir    - Directory that containd the image files. The images are flt for 
;             pre-SM04 data and .flc for post-SM04.
;   prefix  - String that contains a unique identifier for the current version 
;             of the IDC table. Usually a date string like '0205'. This will 
;	      be prepended to the front of every file written to make sure 
;	      not to overwrite old files.
; OPTIONAL INPUT PARAMETERS:
;   odir    - Directory that everything is written to
;             default : /grp/hst/acs/dborncamp/+(pre_sm04 or post_sm04) based on
;             the post flag.
;	     
;   angfile - The angle.stat file from Vera's coeff files. This file usually 
;             lives with the .coeff files.
;	     default: cdir+angle.stat
;
;   badfile - The file that contains the bad file names. This should only 
;             include files names and no extensions. 
;	     default is odir+badfiles.txt
;
; KEYWORD INPUT PARAMETERS:
;   post - Tells if working on pre-SM04 or post-SM04 data. It tells which 
;          directory to write to and which kind of images to look for.
;
; OUTPUTS:
;   odir+prefix+'_pav3_allangle.stat' - contains a concatinated list of ra, dec
;   roll angles, pav3 and orient at. This list will also determine what is 
;   included in the fit later on.
;
;   file name, ra, dec,crval1,crval2,orientat, vera's angle, corrected angle, roll angle, calculated roll, scale in v2v3 system.
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
;   12/05/13 - Dave Borncamp - Created
;   01/27/14 - DB - Upgraded to program, added error checking and logic to find
;                    the correct files.
;   02/21/14 - DB - Updated documentation. 
;
;   Apr 11 2014 DMB - Updated to read in the header date and corretly get the 
;              roll from acstroll which now uses the correct v2v3 ref 
;              given a keyword. This should be smart enough to use the new
;               keyword automaticly. It will now output 2 files for post 
;               data; one before 2011 and one after.
;
;-

pro imcomatch, cdir,idir,prefix,post=POST,odir=ODIR,angfile=ANGFILE,$
   badfile=BADFILE
;error checking add /user/dborncamp/idl/buie/ to !path
self='imcomatch'
if badpar(cdir,7,0,caller=self+' cdir ') then return 
if badpar(idir,7,0,caller=self+' idir ') then return 
if badpar(prefix,7,0,caller=self+' prefix ') then return 
if badpar(post,[0,1,2],0,caller=self+' post ',default=0) then return 
 if post then begin 
    sm='post_sm04/'
    fitsext='flc.fits'
 endif else begin 
    sm='pre_sm04/'
    fitsext='fl?.fits'
 endelse    
;use a default directory, get correct filter
 filter=strlowcase(strmid(cdir,strpos(strlowcase(cdir),'/f')+1,5))
if badpar(odir,[0,7],0,caller=self+' cdir ',$
   default='/grp/hst/acs/dborncamp/'+sm+filter+'/') then return 
if badpar(angfile,[0,7],0,caller=self+' angfile ',$
   default=cdir+'angle.stat') then return 
if badpar(badfile,[0,7],0,caller=self+' badfile ',$
   default=odir+'badresid.txt') then return 

ofile=odir+prefix+'_pav3_allangle.stat'
;ofile2=odir+prefix+'_11_pav3_allangle.stat'

;make sure things are in agreement
if strpos(odir,sm) lt 0 then begin
   print,'!! Post flag may be incorrect... '
   print,'cdir: '+cdir
   print,'post: ',post
   print,'odir: '+odir
   ans=''
   read,ans,prompt='Is this correct, move on? (yes or no) '
   if not strcmp('Yes',ans,/fold) then return
endif

;make sure the directory exists, if not, ask to make it.
if not exists(odir) then begin
   ans=''
   print,'!! Directory: '+odir+' does not exist.'
   read,ans,prompt='Would you like this directory to be created? (yes or no). '
   if strcmp('Yes',ans,/fold) then file_mkdir,odir else begin
      print,'Directory '+odir+' will not be created '+self+' quitting.'
      return
   endelse
endif   

;find the files
cfiless=file_search(cdir+'*1.coeffs',count=cnfiles)
ifiless=file_search(idir+'*'+fitsext,count=infiles)

readcol,angfile,afiles,ang_stat,cor_stat,format='a,d,d',/silent,count=n_angle

;check the angle file for duplicates
u=uniq(afiles,sort(afiles))
na_uniq=n_elements(u)
if na_uniq ne n_angle then begin
    print,self+' !! Warning! '
    print,'There are '+strn(na_uniq)+' unique file names in the angle file.'
    print,'It does not equal the total number of files '+strn(n_angle)
    ans=''
    read,ans,prompt='This could be a problem, Continue anyway? (y or yes) '
    if not (strcmp('Yes',ans,/fold)) then begin
        print,'Quitting...'
        return
    endif
endif


;parse individual names
cfile=strmid(cfiless,17,9,/reverse)
ifile=strmid(ifiless,17,9,/reverse)
afile=strmid(afiles,17,9,/reverse)

;reject bad images from file badresid.txt
if exists(badfile) then begin 
   readcol,badfile,bfile,format='a',count=n_bad,/silent
   if n_bad gt 0 then begin
      print,'Taking out bad files based on bad residuals:'
      forprint,bfile
      match,bfile,afile,ind1,ind2
      afile[ind2]=''
      ang_stat[ind2]=99999
      cor_stat[ind2]=99999
   endif
endif

;match the coefficient files with the images
match,cfile,ifile,ind1,ind2 

cfile=cfile[ind1]
cfiles=cfiless[ind1]
ifile=ifile[ind2]
ifiles=ifiless[ind2]

;everything should be matched and sorted after this:
match,afile,ifile,ind1,ind2,count=nmatch
afile=afile[ind1]
ang_stat=ang_stat[ind1]
cor_stat=cor_stat[ind1]
ifile=ifile[ind2]
ifiles=ifiles[ind2]
cfile=cfile[ind2]
cfiles=cfiles[ind2]

;forprint,afile,ifile,cfile
;ep=dblarr(nmatch)  ;useful for debugging

;check for missing images
print,'number of files matched ',n_elements(ifile)
for i=0,n_elements(afile)-1 do $
   if not exists(idir+afile[i]+'_'+fitsext) then $
      print,'missing image file: '+idir+afile[i]+'_'+fitsext

if exists(ofile) then file_delete,ofile
;if exists(ofile2) then file_delete,ofile2
openw,iunit,ofile,/get_lun,width=210
;openw,iunit2,ofile2,/get_lun,width=210
;add a header
printf,iunit,'name              ra               dec             crval1             crval2         orientat          ang_stat         corr_stat          pa_v3           episalon          vafactor'
;printf,iunit2,'name              ra               dec             crval1         crval2        orientat       ang_stat       corr_stat        pa_v3           episalon        vafactor'

format='(a9, 10d18.11)'

;look at the headers
for i=0,nmatch-1 do begin
;   print,ifile[i],' ',afile[i],' ',cfile[i]
   if ifile[i] ne afile[i] then print,'*afiles do not match! There is a problem'
   if ifile[i] ne cfile[i] then print,'*cfiles do not match! There is a problem'

   hdr0=headfits(ifiles[i],exten=0)
   hdr1=headfits(ifiles[i],exten=1)

   ddate=datesconv(sxpar(hdr0,'DATE-OBS'))
   pa_v3=sxpar(hdr0,'PA_V3')
   dec=sxpar(hdr0,'DEC_TARG')
   ra=sxpar(hdr0,'RA_TARG')
   crval1=sxpar(hdr1,'CRVAL1')
   crval2=sxpar(hdr1,'CRVAL2')
   vafactor=sxpar(hdr1,'VAFACTOR')
   orientat=double(sxpar(hdr1,'ORIENTAT'))
   ;idc=sxpar(hdr0,'IDCTAB')

   ;siaf tables list date as date.#day_in_year make sure to convert
   ;there is probably a better way of implementing this but this is quick
   pre_date=2009.   ;the pre change (happened at sm04) should be 2009.6166
   if ddate lt pre_date then begin
      episalon=acstroll(crval2,pa_v3,pre=1)
      printf,iunit,ifile[i],ra,dec,crval1,crval2,orientat,ang_stat[i],$
                   cor_stat[i],pa_v3,episalon,vafactor,format=format
   endif
;   if (ddate gt pre_date) and (ddate lt post_date) then begin
;      episalon=acstroll(crval2,pa_v3,post=1)
;      printf,iunit,ifile[i],ra,dec,crval1,crval2,orientat,ang_stat[i],$
;                   cor_stat[i],pa_v3,episalon,vafactor
;   endif
   if ddate gt pre_date then begin 
      episalon=acstroll(crval2,pa_v3,post=1)
      printf,iunit,ifile[i],ra,dec,crval1,crval2,orientat,ang_stat[i],$
                   cor_stat[i],pa_v3,episalon,vafactor,format=format
   endif

   ;episalon=acstroll(crval2,pa_v3,post=post);pa_v3_corr
   ;ep[i]=episalon;keep for debugging

   ;printf,iunit,ifile[i],ra,dec,crval1,crval2,orientat,ang_stat[i],cor_stat[i],$
   ;   pa_v3,episalon,vafactor
endfor

free_lun,iunit;,iunit2
print,'writing: '+ofile

;if the second file (used for eleven) has nothing in it, delete it.
;if file_lines(ofile2) lt 2 then file_delete,ofile2 else $
;   print,'writing: '+ofile2

print,'imcomatch successfully completed'

end
