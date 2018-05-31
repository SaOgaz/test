;+
;
;press enter if nothing is wrong, otherwise type it
;
;cdir='/grp/hst/acs/verap/DISTORION_new/F435W_2009/meta_pix_ref2raw_5th_test3/'
;outfile='badresid.txt'
;
;cdir - place to look for coefficients to plot
;
;odir - directory to write data, will default to
;       '/grp/hst/acs/dborncamp/'+sm+filter+'/'
;
;write - flag to write data or not
;
;verbose - print a lot to screen
;
;post - pre or post SM04 data, 0 for pre, 1 for post
;-

pro residlook,cdir,write=WRITE,verbose=VERBOSE,post=POST,odir=ODIR
self=' residlook '
if badpar(cdir,7,[0,1],caller=self+' cdir ') then return 
if badpar(write,[0,1,2],0,caller=self+' write ',default=1) then return 
if badpar(verbose,[0,1,2],0,caller=self+' verbose ',default=1) then return 
if badpar(post,[0,1,2],0,caller=self+' post ',default=0) then return 
 if post then sm='post_sm04/' else sm='pre_sm04/'
;use a default directory, get correct filter
 filter=strlowcase(strmid(cdir,strpos(strlowcase(cdir),'/f')+1,5))
if badpar(odir,[0,7],0,caller=self+' cdir ',$
   default='/grp/hst/acs/dborncamp/'+sm+filter+'/') then return 

files=file_search(cdir+'*.resids',count=nfiles)

goodarr=strarr(nfiles)

for i=0,nfiles-1 do begin
   readcol,files[i],id,m1,m2,xr,yr,u,v,rdx,rdy,format='i,f,f,f,f,f,f,f,f',$
        count=ngood,/silent

   plot,xr,yr,psym=4

   ans=''
   read,ans,prompt='What is wrong? (enter for nothing): '

   if ans eq 'q' then begin
       count=0
       break
   endif

   if ans ne '' then begin
      goodarr[i]=ans
      print,files[i]+' have bad match.'
   endif   
endfor

z=where(goodarr ne '',count)

if verbose then begin
   print,''
   print,strn(count)+' files are marked bad out of '+strn(nfiles)
   print,''
   if count gt 0 then print,files[z]+' have a bad match. '+goodarr[z] $
      else print,'No problems!'
endif

if (count eq 0) and exists(odir+'badresid.txt') and write then begin
    print,'Old badresid file found, none of these coefficeints are bad'
    print,'changing name of ' + odir+'badresid.txt to be badresid_old.txt'
    file_move, odir+'badresid.txt',odir+'badresid_old.txt',/overwrite
endif

if write and (count gt 0 ) then begin
   if not exists(odir) then begin
       ans=''
       print,'outdir= ' + outdir
       read,ans,prompt='Out directory does not exist, Creat it? '
       ;only look at the first letter so either yes or y will work
       if strlowcase(strmid(ans,0,1)) eq 'y' then begin
           file_mkdir,odir
       endif else begin
           print,'Not creating direcotry, exiting without writing.'
           return
       endelse
   endif
   name=strmid(files,17,9,/reverse)
   outfile=odir+'badresid.txt'
   print,'Writing: ' + outfile
   if exists(outfile) then begin
       print,'Overwriting old badfile'
       file_delete,outfile
   endif

   openw,ounit,outfile,/get_lun
   for i=0,count-1 do printf,ounit,name[z[i]]
   free_lun,ounit
endif


end
