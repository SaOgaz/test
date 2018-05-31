;
;will fit the TDD coefficients and write them to a file and create the
;time dependency plot 
;



;flags to save plots or timetable. 
saveplot=0
;flag for table creation that Roberto asked for
timetable=0

;prefixes to search on
prefix=['021915_pre','021915_post']

;place to find converted coefficients. Must be in IDC system
dir=['/grp/hst/acs/dborncamp/pre_sm04/',$
     '/grp/hst/acs/dborncamp/post_sm04/']
;directori for images. Will be smart enough to look in any directory under this
;ex if it is: /grp/hst/acs/verap/ then it will find images in:
;/grp/hst/acs/verap/DISTORION_new/
idir='/grp/hst/acs/verap/DISTORION_new/'

;place to write the files 
odir='/grp/hst/acs/dborncamp/dist/all/'



;get the files and make sure they are unique, dont match duplicates
idcfiles=file_search(dir[*]+'*/nomean/'+prefix[*]+'*_*idc.txt',count=numidc)
files=strmid(idcfiles,16,9,/reverse_offset)
idcfiles=idcfiles[uniq(files)]
files=files[uniq(files)]

imgfiles=file_search(idir+'F*/flt/*f??.fits',count=numimg)
ifiles=strmid(imgfiles,17,9,/reverse_offset)
imgfiles=imgfiles[uniq(ifiles)]
ifiles=ifiles[uniq(ifiles)]

match,files,ifiles,ind1,ind2,count=nmatched

idcfiles=idcfiles[ind1]
imgfiles=imgfiles[ind2]

if nmatched ne numidc then begin
   print,'did not match image files correctly'
endif

xcoef=dblarr(numidc,2)
ycoef=dblarr(numidc,2)
xcoef2=dblarr(numidc,2)
ycoef2=dblarr(numidc,2)

exptime=fltarr(numidc)
roll=fltarr(numidc)
ddate=dblarr(numidc)
filter=strarr(numidc)
prepost=strarr(numidc)

for i=0,numidc-1 do begin
   readcol,idcfiles[i],c10,c11,c20,c21,c22,c30,c31,c32,c33,c40,c41,c42,c43,$
      c44,c50,c51,c52,c53,c54,c55,/silent,$
      format='d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d',count=count

   a=strsplit(idcfiles[i],'/')
   prepost=strmid(idcfiles,a[4],4)

   filter[i]=strmid(idcfiles[i],strpos(idcfiles[i],'/f')+1,5)
;   if (filter[i] eq 'f606w') and (prepost eq 'post') then finyr='' else finyr=fin 
;   ifile=idir+strupcase(filter[i])+finyr+'/flt/'+files[i]+fitsext
   hdr=headfits(imgfiles[i],exten=0)
   
   ddate[i]=datesconv(sxpar(hdr,'DATE-OBS'))
   exptime[i]=sxpar(hdr,'EXPTIME')
   roll[i]=sxpar(hdr,'PA_V3')

   xcoef[i,0]=c11[0]
   xcoef[i,1]=c11[2]
   ycoef[i,0]=c11[1]
   ycoef[i,1]=c11[3]

endfor   

pre_date=2009.   ;the pre change (happened at sm04) should be 2009.6166
;post_date=2011.4777  ;the post change (happened when FGS was recalibrated)
post_date=2009.

pre=where(ddate lt pre_date,precount)
;post=where((ddate gt pre_date) and (ddate lt post_date),postcount)
;eleven=where(ddate gt post_date,ecount)
post=where(ddate gt post_date,postcount)

post_ztime=2010.5
;e_ztime=2012.5
pre_ztime=2004.5
xmin=2001.5
xmax=2014.75

z435=where(filter eq 'f435w',c435)
z606=where(filter eq 'f606w',c606)
z814=where(filter eq 'f814w',c814)

sigma=4

;get the fit for pre, post 
prenewyear=ddate[pre]-pre_ztime
precoeff1=goodpoly(prenewyear,ycoef[pre,0],1,sigma,precyfit1,prenewx1,$
   prenewy1) ;for chip1
prealpha1=precoeff1[0]
prebata1=precoeff1[1]
precoeff2=goodpoly(prenewyear,ycoef[pre,1],1,sigma,precyfit2,prenewx2,$
   prenewy2) ;for chip2
prealpha2=precoeff2[0]
prebata2=precoeff2[1]

postnewyear=ddate[post]-post_ztime
postcoeff1=goodpoly(postnewyear,ycoef[post,0],1,sigma,postcyfit1,postnewx1,$
   postnewy1) ;for chip1
postalpha1=postcoeff1[0]
postbata1=postcoeff1[1]
postcoeff2=goodpoly(postnewyear,ycoef[post,1],1,sigma,postcyfit2,postnewx2,$
   postnewy2) ;for chip2
postalpha2=postcoeff2[0]
postbata2=postcoeff2[1]

;now for xterm
xprenewyear=ddate[pre]-pre_ztime
xprecoeff1=goodpoly(prenewyear,xcoef[pre,0],1,sigma,xprecyfit1,xprenewx1,$
   prenewy1) ;for chip1
xprealpha1=precoeff1[0]
xprebata1=precoeff1[1]
xprecoeff2=goodpoly(prenewyear,xcoef[pre,1],1,sigma,xprecyfit2,xprenewx2,$
   prenewy2) ;for chip2
xprealpha2=precoeff2[0]
xprebata2=precoeff2[1]

xpostnewyear=ddate[post]-post_ztime
xpostcoeff1=goodpoly(postnewyear,xcoef[post,0],1,sigma,xpostcyfit1,xpostnewx1,$
   postnewy1) ;for chip1
xpostalpha1=postcoeff1[0]
xpostbata1=postcoeff1[1]
xpostcoeff2=goodpoly(postnewyear,xcoef[post,1],1,sigma,xpostcyfit2,xpostnewx2,$
   postnewy2) ;for chip2
xpostalpha2=postcoeff2[0]
xpostbata2=postcoeff2[1]

;enewyear=ddate[eleven]-e_ztime
;ecoeff1=goodpoly(enewyear,ycoef[eleven,0],1,sigma,ecyfit1,enewx1,$
;   enewy1) ;for chip1
;ealpha1=ecoeff1[0]
;ebata1=ecoeff1[1]
;ecoeff2=goodpoly(enewyear,ycoef[eleven,1],1,sigma,ecyfit2,enewx2,$
;   enewy2) ;for chip2
;ealpha2=postcoeff2[0]
;ebata2=postcoeff2[1]

expscale=500
win=0
window,win,xpos=2500,ypos=500,xsize=1500,ysize=800
setusym,-1

;get some bounds if wanting to plot on exactly the same scale and 'region'
cxmin= (min(xcoef[*,0]) lt min(xcoef[*,1])) ? min(xcoef[*,0]):min(xcoef[*,1])
cxmax= (max(xcoef[*,0]) gt max(xcoef[*,1])) ? max(xcoef[*,0]):max(xcoef[*,1])

cymax= (max(ycoef[*,0]) lt max(ycoef[*,1])) ? max(ycoef[*,0]):max(ycoef[*,1])
cymin= (min(ycoef[*,0]) gt min(ycoef[*,1])) ? min(ycoef[*,0]):min(ycoef[*,1])

;rescale the y axis
diffx1=max(xcoef[*,0])-min(xcoef[*,0])
diffx2=max(xcoef[*,1])-min(xcoef[*,1])
diffx=(diffx1 gt diffx2) ? diffx1:diffx2

diffy1=max(ycoef[*,0])-min(ycoef[*,0])
diffy2=max(ycoef[*,1])-min(ycoef[*,1])
diffy=(diffy1 gt diffy2) ? diffy1:diffy2

!P.Multi = [0,2,2,0,0]
;chip2
plot,ddate,xcoef[*,0],xr=[xmin,xmax],xmargin=[15,2],/nodata,ymargin=[2,8],$
   title='cy (Skew (c11 term) in X) in WFC 1',ytitle='arc-sec/pix',$
   background='ffffff'xl,color='000000'xl,charthick=1.5,yticklen=.03,$
   charsize=1.5,yr=[min(xcoef[*,0])-diffx*.1,min(xcoef[*,0])+diffx+(diffx*.1)]
for i=0,c435-1 do oplot,[ddate[z435[i]]],[xcoef[z435[i],0]],psym=8,$
                     symsize=exptime[z435[i]]/expscale+1,color='ff0000'xl
for i=0,c606-1 do oplot,[ddate[z606[i]]],[xcoef[z606[i],0]],psym=8,$
                     symsize=exptime[z606[i]]/expscale+1,color='00ff00'xl
for i=0,c814-1 do oplot,[ddate[z814[i]]],[xcoef[z814[i],0]],psym=8,$
                     symsize=exptime[z814[i]]/expscale+1,color='0000ff'xl
oplot,ddate[pre],xprecyfit1,color='00000'xl,symsize=2
oplot,ddate[post],xpostcyfit1,color='000000'xl
;chip1
plot,ddate,xcoef[*,1],xr=[xmin,xmax],xmargin=[11,3],/nodata,ymargin=[2,8],$
   title='cy (Skew (c11 term) in X) in WFC 2',color='000000'xl,charthick=1.5,$
   yticklen=.03,charsize=1.5,$
   yr=[min(xcoef[*,1])-diffx*.1,min(xcoef[*,1])+diffx+(diffx*.1)]
for i=0,c435-1 do oplot,[ddate[z435[i]]],[xcoef[z435[i],1]],psym=8,$
                     symsize=exptime[z435[i]]/expscale+1,color='ff0000'xl
for i=0,c606-1 do oplot,[ddate[z606[i]]],[xcoef[z606[i],1]],psym=8,$
                     symsize=exptime[z606[i]]/expscale+1,color='00ff00'xl
for i=0,c814-1 do oplot,[ddate[z814[i]]],[xcoef[z814[i],1]],psym=8,$
                     symsize=exptime[z814[i]]/expscale+1,color='0000ff'xl
oplot,ddate[pre],xprecyfit2,color='00000'xl,symsize=2
oplot,ddate[post],xpostcyfit2,color='000000'xl

;chip2
plot,ddate,ycoef[*,0],xr=[xmin,xmax],xmargin=[15,2],/nodata,ymargin=[4,2],$
   ytitle='arc-sec/pix',xtitle='Date (Decimil Years)',$
   title='cy (Rotation in Y) in WFC 1',color='000000'xl,charthick=1.5,$
   yticklen=.03,charsize=1.5;,yr=[cymin,cymax]
for i=0,c435-1 do oplot,[ddate[z435[i]]],[ycoef[z435[i],0]],psym=8,$
                     symsize=exptime[z435[i]]/expscale+1,color='ff0000'xl
for i=0,c606-1 do oplot,[ddate[z606[i]]],[ycoef[z606[i],0]],psym=8,$
                     symsize=exptime[z606[i]]/expscale+1,color='00ff00'xl
for i=0,c814-1 do oplot,[ddate[z814[i]]],[ycoef[z814[i],0]],psym=8,$
                     symsize=exptime[z814[i]]/expscale+1,color='0000ff'xl
oplot,ddate[pre],precyfit1,color='00000'xl,symsize=2
oplot,ddate[post],postcyfit1,color='000000'xl

;chip1
plot,ddate,ycoef[*,1],xr=[xmin,xmax],xmargin=[11,3],/nodata,ymargin=[4,2],$
   title='cy (Rotation in Y) in WFC 2',xtitle='Date (Decimil Years)',$
   color='000000'xl,charthick=1.5,yticklen=.03,charsize=1.5;,yr=[cymin,cymax]
for i=0,c435-1 do oplot,[ddate[z435[i]]],[ycoef[z435[i],1]],psym=8,$
                     symsize=exptime[z435[i]]/expscale+1,color='ff0000'xl
for i=0,c606-1 do oplot,[ddate[z606[i]]],[ycoef[z606[i],1]],psym=8,$
                     symsize=exptime[z606[i]]/expscale+1,color='00ff00'xl
for i=0,c814-1 do oplot,[ddate[z814[i]]],[ycoef[z814[i],1]],psym=8,$
                     symsize=exptime[z814[i]]/expscale+1,color='0000ff'xl
oplot,ddate[pre],precyfit2,color='000000'xl
oplot,ddate[post],postcyfit2,color='000000'xl

title='Time Dependency for F606W, F435W & F814W'
xyouts,.35,.96,title,/normal,color=0,charsize=2,charthick=2
xyouts,.38,.93,'F606W ',/normal,color='00ff00'xl,charsize=2,charthick=2
xyouts,.5,.93,'F435W ',/normal,color='ff0000'xl,charsize=2,charthick=2
xyouts,.62,.93,'F814W ',/normal,color='0000ff'xl,charsize=2,charthick=2
xyouts,.425,.93,' -'+strn(c606),/normal,color=0,charsize=1.5;,charthick=2
xyouts,.545,.93,' -'+strn(c435),/normal,color=0,charsize=1.5;,charthick=2
xyouts,.665,.93,' -'+strn(c814),/normal,color=0,charsize=1.5;,charthick=2
   

!P.Multi = 0
setusym,1

;write it out as both a jpg and png
if saveplot then begin
   tvgrab,'entire_time_dep.png',0,/png
   tvgrab,'entire_time_dep.jpg',0
   ofile='all_TimeDependency.jpg'
   tvgrab,ofile,win
   print,'writing: '+ofile
endif

;write the timedependency to a file for all 
ans=''
timefile=odir+prefix[0]+'_sm04_alltime_coeffs.txt' 
if saveplot and exists(timefile) then begin
   ans='n'
   read,ans,prompt=timefile+' already exists, would you like to overwrite (default no)? '
endif
;write the file if yser answers yes or y
if (ans eq 'y') or (ans eq 'yes') then begin 
   openw,tunit,timefile,/get_lun
   print,'writing: '+timefile
   printf,tunit,'Time dependant beta term for coefficients data.'
   printf,tunit,'Created on: '+systime()
   printf,tunit,'zero time: ',pre_ztime
   printf,tunit,'Ybeta for chip 1 (exten = 4): ',prebata1,format='(a,d)'
   printf,tunit,'Ybeta for chip 2 (exten = 1): ',prebata2,format='(a,d)'
   printf,tunit,'Yalpha for chip 1 (exten = 4): ',prealpha1,format='(a,d)'
   printf,tunit,'Yalpha for chip 2 (exten = 1): ',prealpha2,format='(a,d)'
   printf,tunit,'Xbeta for chip 1 (exten = 4): ',xprebata1,format='(a,d)'
   printf,tunit,'Xbeta for chip 2 (exten = 1): ',xprebata2,format='(a,d)'
   printf,tunit,'Xalpha for chip 1 (exten = 4): ',xprealpha1,format='(a,d)'
   printf,tunit,'Xalpha for chip 2 (exten = 1): ',xprealpha2,format='(a,d)'        
   free_lun,tunit
endif

print,'Ybeta for chip 1 (exten = 4): ',prebata1,format='(a,d)'
print,'Ybeta for chip 2 (exten = 1): ',prebata2,format='(a,d)'
print,'Yalpha for chip 1 (exten = 4): ',prealpha1,format='(a,d)'
print,'Yalpha for chip 2 (exten = 1): ',prealpha2,format='(a,d)'
print,'Xbeta for chip 1 (exten = 4): ',xprebata1,format='(a,d)'
print,'Xbeta for chip 2 (exten = 1): ',xprebata2,format='(a,d)'
print,'Xalpha for chip 1 (exten = 4): ',xprealpha1,format='(a,d)'
print,'Xalpha for chip 2 (exten = 1): ',xprealpha2,format='(a,d)' 

if timetable then begin
    tablename=odir+strmid(prefix[0],0,6)+'_time_table.txt'
    if exists(tablename) then file_delete,tablename
    openw,tablun,tablename,/get_lun
    print,'Writing timetable: '+tablename
    printf,tablun,'filename ','cy_rotx_wfc1','cy_rotx_wfc2','cy_roty_wfc1',$
        'cy_roty_wfc2','dec_year',$
        format='(6a14)'
    for i=0,numidc-1 do begin
        printf,tablun,files[i],xcoef[i,0],xcoef[i,1],ycoef[i,0],$
            ycoef[i,1],ddate[i],$
            format='(a14,4d14.10,f14.3)'
    endfor
    free_lun,tablun
endif



;timefile=odir+prefix[2]+'_sm04_alltime_coeffs.txt' 
;if exists(timefile) then begin
;   ans='n'
;   read,ans,prompt=timefile+' already exists, would you like to overwrite (default no)? '
;endif
;if (ans eq 'y') or (ans eq 'yes') then begin 
;   openw,tunit,timefile,/get_lun
;   print,'writing: '+timefile
;   printf,tunit,'Time dependant beta term for F606W, F435W & F814 eleven data.'
;   printf,tunit,'Created on: '+systime()
;   printf,tunit,'zero time: ',e_ztime
;   printf,tunit,'beta for chip 1 (exten = 4): ',ebata1,format='(a,d)'
;   printf,tunit,'beta for chip 2 (exten = 1): ',ebata2,format='(a,d)'
;   printf,tunit,'alpha for chip 1 (exten = 4): ',ealpha1,format='(a,d)'
;   printf,tunit,'alpha for chip 2 (exten = 1): ',ealpha2,format='(a,d)'
;      
;   free_lun,tunit
;endif


end
