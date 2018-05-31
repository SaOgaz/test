force_scale=0 ;0 or 1 to force the scale of the axes to be the same scale for x and y coeffs.
view_term=0 ;which term to view (1 to 21). 0 will view all terms and prompt user for next plot.
pad=.07 ;how much of a padding to put on the y axis. .1 (10%) is a good place to start
exten=1 ;which extension to look at (which chip, exten 1 => chip 2) 
idc=1
over=0 ;overplot each filter fit
numbers=0 ;put numbers on plot
badtxt='badresid.txt'
timetable=0
corrected=1
save_ps=0
jay_date=1
extra=0

if idc then begin
   prefix=['110917_slh_pre','110917_slh_post']

   dir=[$
      'post_sm04/f435w/nomean/',$
      'post_sm04/f606w/nomean/',$
      'post_sm04/f814w/nomean/',$
      'post_sm04/f775w/nomean/',$
      'pre_sm04/f435w/nomean/',$
      'pre_sm04/f606w/nomean/',$
      'pre_sm04/f814w/nomean/',$
      'pre_sm04/f775w/nomean/']

   ytitle='arc-sec/pix'

endif else begin

dir=['/grp/hst/acs3/verap/DISTORTION/F606W_2009/meta_pix.v22/',$
      '/grp/hst/acs3/verap/DISTORTION/F814W_2009/meta_pix.v2/',$
      '/grp/hst/acs3/verap/DISTORTION/F435W_2009/meta_pix.v2/',$
      '/grp/hst/acs3/verap/DISTORTION/F775W_2009_newcorr/meta_pix.v3/']

   ytitle='pixels'
endelse 


idir=['/grp/hst/acs2/astrometric_ref/47tuc/wfc/f606w/',$
      '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f814w/',$
      '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f435w/',$
      '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f775w/',$
      '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f475w/',$
      '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f625w/',$
      '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f658n/',$
      '/grp/hst/acs2/astrometric_ref/47tuc/wfc/f555w/']

odir=[$
      'pre_sm04/f606w/',$
      'pre_sm04/f814w/',$
      'pre_sm04/f435w/',$
      'pre_sm04/f555w/',$
      'post_sm04/f606w/',$
      'post_sm04/f814w/',$
      'post_sm04/f435w/',$
      'post_sm04/f555w/']

;files=file_search(dir+'*_1.coeffs',count=nfiles)
;get the date of all of the files
;find all of the coeff files
counter=0
files=''
filter=strarr(n_elements(dir))
for i=0,n_elements(dir)-1 do begin
    if idc then $
        search=dir[i]+prefix[*]+'*_*idc.txt' $
    else search=dir[i]+'*_'+strn(exten)+'.coeffs'
    ;exclude not found directories, file search will return empty string on fail
    if counter eq 0 then begin
        temp=file_search(search)
        if temp[0] ne '' then begin
            files=temp
            counter++
        endif
    endif else begin
        files=[files,file_search(search)]
    endelse
    filter[i]=strmid(dir[i],strpos(dir[i],'/f')+1,5)
endfor

if idc then root=strmid(files,16,9,/reverse_offset) else root=strmid(files,17,9,/reverse_offset)

nonuniq=n_elements(root)
root=root[uniq(root)]
files=files[uniq(root)]

;find all of the image files that match what was found for the coeff files
counter=0
for i=0,n_elements(idir)-1 do begin
    if counter eq 0 then imfiles=file_search(idir[i]+root+'_fl?.fits') $
        else imfiles=[imfiles,file_search(idir[i]+root+'_fl?.fits')]
    counter++
endfor

imroot=strmid(imfiles,17,9,/reverse_offset)

nonuniqim=n_elements(imroot)
imroot=imroot[uniq(imroot)]
imfiles=imfiles[uniq(imroot)]

;reject bad images from file badresid.txt
for i=0,n_elements(odir)-1 do begin
    badfile=odir[i]+badtxt
    ;print,'badfile: '+badfile
   if exists(badfile) then begin 
      readcol,badfile,bfile,format='a',count=n_bad
      if n_bad gt 0 then begin
         print,'Taking out bad files based on manually checked bad residuals '+odir[i]
         forprint,bfile
         match,bfile,root,ind1,ind2
         root[ind2]='-1'
      endif
   endif
endfor

;match the image and coeff files
match,root,imroot,ind1,ind2,count=nfiles
files=files[ind1]
;root=root[uniq(ind1)]
imfiles=imfiles[ind2]
imroot=imroot[ind2]
;nfiles=n_elements(files)

;get the dates now that everything in the right order
ddate=dblarr(nfiles)
help,imfiles
print,imfiles[0]

if jay_date then begin
    print,'Overriding ddate with Jays date solutions'
    imgdir='/grp/hst/acs2/astrometric_ref/47tuc/wfc/'
    filts=uniq(filter)
    for i=0,n_elements(filts)-1 do begin
        readcol,imgdir+filter[filts[i]]+'/readheader.out',jrootname,pid,date_obs,$
            time_obs,ra,dec,pav3,fil,expt,rdate,vafactor,dra,ddec,d,d,d,$
            format='a,l,a,a,a,a,f,a,i,d,d,f,f,a,a,a',/silent

        rdate=rdate+2000
        match,imroot,jrootname,ind1,ind2
        ddate[ind1]=rdate[ind2]
    endfor
endif else begin
    for i=0,nfiles-1 do begin
        if imfiles[i] eq '' then continue
        hdr=headfits(imfiles[i],exten=0)
        dateobs=sxpar(hdr,'DATE-OBS')
        ddate[i]=datesconv(dateobs)
    endfor
endelse

z=where(ddate eq 0.0,count,complement=zgood)
if jay_date and (count gt 0) then begin
    print,'something does not have a good jay_date, not in read_header.out'
    print,'running datesconv on it'
    print,count
    for i=0,count-1 do begin
        hdr=headfits(imfiles[z[i]],exten=0)
        ddate[z[i]]=datesconv(sxpar(hdr,'DATE-OBS'))
    endfor
endif

order=5
terms = (order+1)*(order+2)/2

;create arrays for things to live
x_coeff=dblarr(nfiles,21)
y_coeff=dblarr(nfiles,21)
x_error=fltarr(nfiles,21)
y_error=fltarr(nfiles,21)
x_id=lonarr(nfiles,21)
y_id=lonarr(nfiles,21)
x_rms=fltarr(nfiles)
y_rms=fltarr(nfiles)
n_stars=lonarr(nfiles)
filter=strarr(nfiles)

;read in files and populate arrays
for i=0,nfiles-1 do begin  ;files
   if idc then begin
      if files[i] eq '' then continue
      readcol,files[i],c10,c11,c20,c21,c22,c30,c31,c32,c33,c40,c41,$
          c42,c43,c44,c50,c51,c52,c53,c54,c55,/silent,$
      format='d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d,d',count=count

      if exten eq 1 then place=2 else place=0

      x_coeff[i,0]=.05
      x_coeff[i,1]=c10[place]
      x_coeff[i,2]=c11[place]
      x_coeff[i,3]=c20[place]
      x_coeff[i,4]=c21[place]
      x_coeff[i,5]=c22[place]
      x_coeff[i,6]=c30[place]
      x_coeff[i,7]=c31[place]
      x_coeff[i,8]=c32[place]
      x_coeff[i,9]=c33[place]
      x_coeff[i,10]=c40[place]
      x_coeff[i,11]=c41[place]
      x_coeff[i,12]=c42[place]
      x_coeff[i,13]=c43[place]
      x_coeff[i,14]=c44[place]
      x_coeff[i,15]=c50[place]
      x_coeff[i,16]=c51[place]
      x_coeff[i,17]=c52[place]
      x_coeff[i,18]=c53[place]
      x_coeff[i,19]=c54[place]
      x_coeff[i,20]=c55[place]

      y_coeff[i,0]=.05
      y_coeff[i,1]=c10[place+1]
      y_coeff[i,2]=c11[place+1]
      y_coeff[i,3]=c20[place+1]
      y_coeff[i,4]=c21[place+1]
      y_coeff[i,5]=c22[place+1]
      y_coeff[i,6]=c30[place+1]
      y_coeff[i,7]=c31[place+1]
      y_coeff[i,8]=c32[place+1]
      y_coeff[i,9]=c33[place+1]
      y_coeff[i,10]=c40[place+1]
      y_coeff[i,11]=c41[place+1]
      y_coeff[i,12]=c42[place+1]
      y_coeff[i,13]=c43[place+1]
      y_coeff[i,14]=c44[place+1]
      y_coeff[i,15]=c50[place+1]
      y_coeff[i,16]=c51[place+1]
      y_coeff[i,17]=c52[place+1]
      y_coeff[i,18]=c53[place+1]
      y_coeff[i,19]=c54[place+1]
      y_coeff[i,20]=c55[place+1]

   endif else begin ; Not IDC
      readcol,files[i],xid,xcf,xerr,yid,ycf,yerr,xfit,yfit,nstars,$
         format='i,f,f,i,f,f,f,f,l',count=n_coeffs,/silent
   
      n_stars[i]=nstars[0]
      x_rms[i]=xfit[0]
      y_rms[i]=yfit[0]
      
      for j=0,n_coeffs-1 do begin ;coeffs
         x_coeff[i,j]=xcf[j]
         y_coeff[i,j]=ycf[j]
         x_error[i,j]=xerr[j]
         y_error[i,j]=yerr[j]
         x_id[i,j]=xid[j]
         y_id[i,j]=yid[j]
      endfor
  endelse
  filter[i]=strmid(files[i],strpos(strlowcase(files[i]),'/f')+1,5)
endfor

;try a normalization to look for interesting things. not actually plotted
;but useful for .r script...
normx=fltarr(nfiles,21)
normy=fltarr(nfiles,21)
normx_err=fltarr(nfiles,21)
normy_err=fltarr(nfiles,21)
for i=0,nfiles-1 do begin ;files
   for j=0,20 do begin    ;coeff
      normx[i,j]=x_coeff[i,j]/mean(x_coeff[*,j])
      normy[i,j]=y_coeff[i,j]/mean(y_coeff[*,j])
      normx_err[i,j]=x_coeff[i,j]/mean(x_error[*,j])
      normy_err[i,j]=y_coeff[i,j]/mean(y_error[*,j])

   endfor
endfor 


;sort the filters
z435p=where(strupcase(filter) eq 'F435W',c435p)
z606p=where(strupcase(filter) eq 'F606W',c606p)
z814p=where(strupcase(filter) eq 'F814W',c814p)
z555p=where(strupcase(filter) eq 'F775W',c555p)

;fit the coefficients for term 2
split=2009
preztime=2004.5
postztime=2012.0

z435pre=where((ddate lt split) and (strupcase(filter) eq 'F435W'),n435pre)
z435post=where((ddate gt split) and (strupcase(filter) eq 'F435W'),n435post)
z606pre=where((ddate lt split) and (strupcase(filter) eq 'F606W'),n606pre)
z606post=where((ddate gt split) and (strupcase(filter) eq 'F606W'),n606post)
z814pre=where((ddate lt split) and (strupcase(filter) eq 'F814W'),n814pre)
z814post=where((ddate gt split) and (strupcase(filter) eq 'F814W'),n814post)
z555pre=where((ddate lt split) and (strupcase(filter) eq 'F775W'),n555pre)
z555post=where((ddate gt split) and (strupcase(filter) eq 'F775W'),n555post)

;Should make sure that the pre post counts are not bigger then the total filter
;counts... 

zpre=where(ddate lt split,npre)
zpost=where(ddate gt split,npost)
;only want second index for this part
order=1 ;linear
sigma=10 ;dont want to remove any points
prenewyear=ddate-preztime
postnewyear=ddate-postztime


;fit for x
if n435pre gt 0 then $
   pre435coeff=goodpoly(prenewyear[z435pre],x_coeff[z435pre,2],order,sigma,$
       pre435x_coeff_2,pre435ddate,newx1)
if n435post gt 0 then $
   post435coeff=goodpoly(postnewyear[z435post],x_coeff[z435post,2],order,sigma,$
       post435x_coeff_2,post435ddate,newx1)

if n606pre gt 0 then $
   pre606coeff=goodpoly(prenewyear[z606pre],x_coeff[z606pre,2],order,sigma,$
       pre606x_coeff_2,pre606ddate,newx1)
if n606post gt 0 then $
   post606coeff=goodpoly(postnewyear[z606post],x_coeff[z606post,2],order,sigma,$
       post606x_coeff_2,post606ddate,newx1)

if n814pre gt 0 then $
   pre814coeff=goodpoly(prenewyear[z814pre],x_coeff[z814pre,2],order,sigma,$
       pre814x_coeff_2,pre814ddate,newx1)
if n814post gt 0 then $
   post814coeff=goodpoly(postnewyear[z814post],x_coeff[z814post,2],order,sigma,$
       post814x_coeff_2,post814ddate,newx1)

if n555pre gt 0 then $
   pre555coeff=goodpoly(prenewyear[z555pre],x_coeff[z555pre,2],order,sigma,$
       pre555x_coeff_2,pre555ddate,newx1)
if n555post gt 0 then $
   post555coeff=goodpoly(postnewyear[z555post],x_coeff[z555post,2],order,sigma,$
       post555x_coeff_2,post814ddate,newx1)



if npre gt 0 then $
   preallcoeffx=goodpoly(prenewyear[zpre],x_coeff[zpre,2],order,sigma,$
       preallx_coeff_2,preallddate,newx1)
if npost gt 0 then $
   postallcoeffx=goodpoly(postnewyear[zpost],x_coeff[zpost,2],order,sigma,$
       postallx_coeff_2,postallddate,newx1)


;fit for y
if n435pre gt 0 then $
   pre435coeff=goodpoly(prenewyear[z435pre],y_coeff[z435pre,2],order,sigma,$
       pre435y_coeff_2,pre435ddate,newy1)
if n435post gt 0 then $
   post435coeff=goodpoly(postnewyear[z435post],y_coeff[z435post,2],order,sigma,$
       post435y_coeff_2,post435ddate,newy1)

if n606pre gt 0 then $
   pre606coeff=goodpoly(prenewyear[z606pre],y_coeff[z606pre,2],order,sigma,$
       pre606y_coeff_2,pre606ddate,newy1)
if n606post gt 0 then $
   post606coeff=goodpoly(postnewyear[z606post],y_coeff[z606post,2],order,sigma,$
       post606y_coeff_2,post606ddate,newy1)

if n814pre gt 0 then $
   pre814coeff=goodpoly(prenewyear[z814pre],y_coeff[z814pre,2],order,sigma,$
       pre814y_coeff_2,pre814ddate,newy1)
if n814post gt 0 then $
   post814coeff=goodpoly(postnewyear[z814post],y_coeff[z814post,2],order,sigma,$
       post814y_coeff_2,post814ddate,newy1)


if n555pre gt 0 then $
   pre555coeff=goodpoly(prenewyear[z555pre],y_coeff[z555pre,2],order,sigma,$
       pre555y_coeff_2,pre555ddate,newy1)
if n814post gt 0 then $
   post555coeff=goodpoly(postnewyear[z555post],y_coeff[z555post,2],order,sigma,$
       post555y_coeff_2,post555ddate,newy1)


if npre gt 0 then $
   preallcoeffy=goodpoly(prenewyear[zpre],y_coeff[zpre,2],order,sigma,$
       preally_coeff_2,preallddate,newy1)
if npost gt 0 then $
   postallcoeffy=goodpoly(postnewyear[zpost],y_coeff[zpost,2],order,sigma,$
       postally_coeff_2,postallddate,newy1)


;get bounds and plot
xmin=2001.5
xmax=2015.75

;pad=pad+1 ;may want to change how this in implemented
window,0,xsize=1100,ysize=700

!P.Multi = [0,1,2,0,0]
current=0
while (current lt terms)do begin
    i=current
    ;add the ability to look at single term
    if view_term ne 0 then begin
        i=view_term-1
        current=view_term-1
    endif
    ;print,'while ',i,current,terms  :debuggin line
    ;window,0
    ;force the scale to be the same between both of them
    if force_scale then begin
        cmin= (min(x_coeff[*,i]) lt min(y_coeff[*,i])) ? min(x_coeff[*,i]):min(y_coeff[*,i])
        cmax= (max(x_coeff[*,i]) gt max(y_coeff[*,i])) ? max(x_coeff[*,i]):max(y_coeff[*,i])
        cmin=cmin-abs(cmin*pad)  ;give a little padding
        cmax=cmax+abs(cmax*pad)
        xcmin=cmin
        xcmax=cmax
        ycmin=cmin
        ycmax=cmax
    endif else begin
;        xcmin=min(x_coeff[*,i])-abs(min(x_coeff[*,i])*pad)
;        xcmax=max(x_coeff[*,i])+abs(max(x_coeff[*,i])*pad)
;        ycmin=min(y_coeff[*,i])-abs(min(y_coeff[*,i])*pad)
;        ycmax=max(y_coeff[*,i])+abs(max(y_coeff[*,i])*pad)
        xcmin=min(x_coeff[*,i])-abs(variance(x_coeff[*,i])*pad)
        xcmax=max(x_coeff[*,i])+abs(variance(x_coeff[*,i])*pad)
        ycmin=min(y_coeff[*,i])-abs(variance(y_coeff[*,i])*pad)
        ycmax=max(y_coeff[*,i])+abs(variance(y_coeff[*,i])*pad)
    endelse
    if i ne 2 then begin 
        plot,ddate,x_coeff[*,i],/nodata,xr=[xmin,xmax],yr=[xcmin,xcmax],$
            xtitle='Year',color='000000'xl,xmargin=[15,2],$
            background='ffffff'xl,charthick=1.75,ytitle=ytitle,charsize=1.5,$
            title='X-coeff for term: A'+strn(i+1)+' in Extension: '+strn(exten)
    
        for j=0,c435p-1 do oplot,[ddate[z435p[j]]],[x_coeff[z435p[j],i]],$
                                color='ff0000'xl,psym=4,thick=2 ;blue
        for j=0,c606p-1 do oplot,[ddate[z606p[j]]],[x_coeff[z606p[j],i]],$
                                color='00ff00'xl,psym=4,thick=2 ;green
        for j=0,c814p-1 do oplot,[ddate[z814p[j]]],[x_coeff[z814p[j],i]],$
                                color='0000ff'xl,psym=4,thick=2 ;red
        for j=0,c555p-1 do oplot,[ddate[z555p[j]]],[x_coeff[z555p[j],i]],$
                                color='ffff00'xl,psym=4,thick=2 ;cyan

    endif
    ;over plot new fits only if i=2
    if i eq 2 then begin
         if corrected then begin
            rdate=fltarr(nfiles)
            corrected=dblarr(nfiles)

            rdate[zpre]=2004.5
            rdate[zpost]=2012.0

            if npre gt 0 then pre_cxtdd=pre606coeff[0]+(pre606coeff[1]*(ddate[zpre]-rdate[zpre]))
            if npost gt 0 then post_cxtdd=post606coeff[0]+(post606coeff[1]*(ddate[zpost]-rdate[zpost]))
            if npre gt 0 then corrected[zpre]=x_coeff[zpre,2]-pre_cxtdd
            if npost gt 0 then corrected[zpost]=x_coeff[zpost,2]-post_cxtdd

            if extra then begin
                !p.multi=0
                window,1,xsize=1100,ysize=700
                cmin=min(corrected)*.9
                cmax=max(corrected)*1.1
                plot,ddate,x_coeff[*,i],/nodata,xr=[xmin,xmax],yr=[cmin,cmax],$
                    xtitle='Year',color='000000'xl,xmargin=[15,2],$
                    background='ffffff'xl,charthick=1.75,ytitle=ytitle,charsize=1.5,$
                    title='Corrected X-coeff for term: A'+strn(i+1)+' in Extension: '+strn(exten)
    
                for j=0,c435p-1 do oplot,[ddate[z435p[j]]],[corrected[z435p[j]]],$
                                        color='ff0000'xl,psym=4,thick=2
                for j=0,c606p-1 do oplot,[ddate[z606p[j]]],[corrected[z606p[j]]],$
                                        color='00ff00'xl,psym=4,thick=2
                for j=0,c814p-1 do oplot,[ddate[z814p[j]]],[corrected[z814p[j]]],$
                                        color='0000ff'xl,psym=4,thick=2
                for j=0,c555p-1 do oplot,[ddate[z555p[j]]],[corrected[z555p[j]]],$
                                        color='ffff00'xl,psym=4,thick=2
                !p.multi=[0,1,2,0,0]  ;reset the plotting space
                wset,0  ;set the window back to other plot
            endif
        endif

        plot,ddate,x_coeff[*,i],/nodata,xr=[xmin,xmax],yr=[xcmin,xcmax],$
            xtitle='Year',color='000000'xl,xmargin=[15,2],$
            background='ffffff'xl,charthick=1.75,ytitle=ytitle,charsize=1.5,$
            title='X-coeff for term: A'+strn(i+1)+' in Extension: '+strn(exten)
    
        for j=0,c435p-1 do oplot,[ddate[z435p[j]]],[x_coeff[z435p[j],i]],$
                                color='ff0000'xl,psym=4,thick=2
        for j=0,c606p-1 do oplot,[ddate[z606p[j]]],[x_coeff[z606p[j],i]],$
                                color='00ff00'xl,psym=4,thick=2
        for j=0,c814p-1 do oplot,[ddate[z814p[j]]],[x_coeff[z814p[j],i]],$
                                color='0000ff'xl,psym=4,thick=2
        for j=0,c555p-1 do oplot,[ddate[z555p[j]]],[x_coeff[z555p[j],i]],$
                                color='ffff00'xl,psym=4,thick=2

        
        if over then begin
            oplot,ddate[z435pre],pre435x_coeff_2,color='ff0000'xl
            oplot,ddate[z435post],post435x_coeff_2,color='ff0000'xl
            oplot,ddate[z606pre],pre606x_coeff_2,color='00ff00'xl
            oplot,ddate[z606post],post606x_coeff_2,color='00ff00'xl
            oplot,ddate[z814pre],pre814x_coeff_2,color='0000ff'xl
            oplot,ddate[z814post],post814x_coeff_2,color='0000ff'xl

            oplot,ddate[z555pre],pre555x_coeff_2,color='ffff00'xl
            oplot,ddate[z555post],post555x_coeff_2,color='ffff00'xl
            ;for y
            oplot,ddate[z435pre],pre435y_coeff_2,color='ff0000'xl
            oplot,ddate[z435post],post435y_coeff_2,color='ff0000'xl
            oplot,ddate[z606pre],pre606y_coeff_2,color='00ff00'xl
            oplot,ddate[z606post],post606y_coeff_2,color='00ff00'xl
            oplot,ddate[z814pre],pre814y_coeff_2,color='0000ff'xl
            oplot,ddate[z814post],post814y_coeff_2,color='0000ff'xl

            oplot,ddate[z555pre],pre555y_coeff_2,color='ffff00'xl
            oplot,ddate[z555post],post555y_coeff_2,color='ffff00'xl
        endif
        if npre gt 0 then $
            oplot,pre606ddate,pre606y_coeff_2,color='000000'xl
            ;oplot,ddate[zpre],preallx_coeff_2,color='000000'xl

        if npost gt 0 then $
           oplot,post606ddate,post606y_coeff_2,color='000000'xl 
           ;oplot,ddate[zpost],postallx_coeff_2,color='000000'xl
        if numbers then begin
            ;overplot numbers for x
            if npre gt 0 then xyouts,.15,.64,'Pre zdate: '+strn(preztime),color='000000'xl,$
                /normal,charsize=1.5
            if npre gt 0 then xyouts,.15,.62,'Pre alhpa: '+strn(preallcoeffx[0]),color='000000'xl,$
                /normal,charsize=1.5
            if npre gt 0 then xyouts,.15,.60,'Pre beta: '+strn(preallcoeffx[1]),color='000000'xl,$
                /normal,charsize=1.5

            if npost gt 0 then xyouts,.65,.64,'Post zdate: '+strn(postztime),color='000000'xl,$
                /normal,charsize=1.5
            if npost gt 0 then xyouts,.65,.62,'Post alhpa: '+strn(postallcoeffx[0]),color='000000'xl,$
                /normal,charsize=1.5
            if npost gt 0 then xyouts,.65,.60,'Post beta: '+strn(postallcoeffx[1]),color='000000'xl,$
                /normal,charsize=1.5
            ;for y
            if npre gt 0 then xyouts,.15,.12,'Pre alhpa: '+strn(preallcoeffy[0]),color='000000'xl,$
                /normal,charsize=1.5
            if npre gt 0 then xyouts,.15,.10,'Pre beta: '+strn(preallcoeffy[1]),color='000000'xl,$
                /normal,charsize=1.5
            if npost gt 0 then xyouts,.65,.12,'Post alhpa: '+strn(postallcoeffy[0]),color='000000'xl,$
                /normal,charsize=1.5
            if npost gt 0 then xyouts,.65,.10,'Post beta: '+strn(postallcoeffy[1]),color='000000'xl,$
                /normal,charsize=1.5
        endif ;end numbers

        print,'Info on fits:'
        print,'Extension: '+strn(exten)
        print,'pre-ztime: '+strn(preztime)
        print,'post-ztime: '+strn(postztime)
        print,' Pre-F435W:'
        if n435pre gt 0 then print,'   alpha: ',pre435coeff[0],format='(a10,f19.16)'
        if n435pre gt 0 then print,'   beta:  ',pre435coeff[1],format='(a10,f19.16)'
        print,' Post-F435W:'
        if n435post gt 0 then print,'   alpha: ',post435coeff[0],format='(a10,f19.16)'
        if n435post gt 0 then print,'   beta:  ',post435coeff[1],format='(a10,f19.16)'
        print,' Pre-F606W:'
        if n606pre gt 0 then print,'   alpha: ',pre606coeff[0],format='(a10,f19.16)'
        if n606pre gt 0 then print,'   beta:  ',pre606coeff[1],format='(a10,f19.16)'
        print,' Post-F606W:'
        if n606post gt 0 then print,'   alpha: ',post606coeff[0],format='(a10,f19.16)'
        if n606post gt 0 then print,'   beta:  ',post606coeff[1],format='(a10,f19.16)'
        print,' Pre-F814W:'
        if n814pre gt 0 then print,'   alpha: ',pre814coeff[0],format='(a10,f19.16)'
        if n814pre gt 0 then print,'   beta:  ',pre814coeff[1],format='(a10,f19.16)'
        print,' Post-F814W:'
        if n814post gt 0 then print,'   alpha: ',post814coeff[0],format='(a10,f19.16)'
        if n814post gt 0 then print,'   beta:  ',post814coeff[1],format='(a10,f19.16)'
        print,' Pre Average:'
        if npre gt 0 then print,'   alpha: ',preallcoeffx[0],format='(a10,f19.16)'
        if npre gt 0 then print,'   beta:  ',preallcoeffx[1],format='(a10,f19.16)'
        print,' Post Average:'
        if npost gt 0 then print,'   alpha: ',postallcoeffy[0],format='(a10,f19.16)'
        if npost gt 0 then print,'   beta:  ',postallcoeffy[1],format='(a10,f19.16)'

    endif ;i=2

    plot,ddate,y_coeff[*,i],/nodata,xr=[xmin,xmax],yr=[ycmin,ycmax],$
        xtitle='Year',title='Y-coeff for term: B'+strn(i+1),color='000000'xl,$
        charsize=1.5,charthick=1.75,ytitle=ytitle,xmargin=[15,2]
    for j=0,c435p-1 do oplot,[ddate[z435p[j]]],[y_coeff[z435p[j],i]],$
                            color='ff0000'xl,psym=4,thick=2
    for j=0,c606p-1 do oplot,[ddate[z606p[j]]],[y_coeff[z606p[j],i]],$
                            color='00ff00'xl,psym=4,thick=2
    for j=0,c814p-1 do oplot,[ddate[z814p[j]]],[y_coeff[z814p[j],i]],$
                            color='0000ff'xl,psym=4,thick=2
    for j=0,c555p-1 do oplot,[ddate[z555p[j]]],[y_coeff[z555p[j],i]],$
                            color='ffff00'xl,psym=4,thick=2

    if (npre gt 0) and (i eq 2) then $
       oplot,pre606ddate,pre606y_coeff_2,color='000000'xl
       ;oplot,ddate[zpre],preally_coeff_2,color='000000'xl
    if (npost gt 0) and (i eq 2) then $
       oplot,post606ddate,post606y_coeff_2,color='000000'xl
       ;oplot,ddate[zpost],postally_coeff_2,color='000000'xl

    ;close if looking at specific term
    ;if view_term ne 0 then break
 
    ;allow user to exit or save.
    ans=''
    valid=1
    read,ans,prompt='enter for next, q to quit, s to save '+strn(i)+' : '
    case ans of
    'q': current = terms
    's': begin
            ans=''
            if save_ps then print,'Remember, saving to a .ps'
            read,ans,prompt='enter save name (blank for default): '
            if ans ne '' then savename=ans else begin
                savedir='/grp/hst/acs/dborncamp/dist/all/'
                if i+1 lt 10 then number='0'+strn(i+1) else number=strn(i+1)
                if idc then begin
                    if save_ps then begin
                        savename=savedir+'coeff_plot_term_'+number+'_'+strn(exten)+'_'+prefix[0]+'_idc.ps'
                    endif else begin
                        savename=savedir+'coeff_plot_term_'+number+'_'+strn(exten)+'_'+prefix[0]+'_idc.png'
                    endelse
                endif else begin ;endif save_ps
                    if save_ps then begin
                        savename=savedir+'coeff_plot_term_'+number+'_'+strn(exten)+'_'+prefix[0]+'_pix.ps'
                    endif else begin
                        savename=savedir+'coeff_plot_term_'+number+'_'+strn(exten)+'_'+prefix[0]+'_pix.png'
                    endelse ;endelse save_ps
                endelse ;end if idc
    
            endelse ;endelse save answer
            ;should be in window 0...
            if not save_ps then begin
                print,'saving: '+savename
                tvgrab,savename,0,/png
            endif else begin ;start plotting in ps
                print,'saving: '+savename
                win2ps,0,savename
            endelse
        end
    '':
    else: begin
            print,'Input not recognized, try again...'
            print,'ans is: '
            help,ans
            current--
            valid=0
        end
    endcase
    current++
    if (view_term ne 0) and (valid eq 1) then current=terms
endwhile   
!P.Multi = 0

if timetable then begin
    writedir='/grp/hst/acs/dborncamp/dist/all/'
    tablename=writedir+'x_'+strn(exten)+'_time_table.txt'
    if exists(tablename) then file_delete,tablename
    openw,tablun,tablename,/get_lun
    print,'Writing timetable: '+tablename
    printf,tablun,'filename ','dec_year','cx_scale',$
        format='(3a14)'
    for i=0,nfiles-1 do begin
        printf,tablun,imroot[i],ddate[i],x_coeff[i,2],$
            format='(a14,f14.3,d16.10)'
    endfor
    free_lun,tablun
endif

end
