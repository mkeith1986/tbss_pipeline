#!/usr/bin/env python3
import sys
import os
import datetime

def echo(msg,fout):
    print(msg)
    fout.write(msg+'\n')

def trimCols(col1,col2,iname,oname,fout):
    echo("Keeping columns "+str(col1)+" to "+str(col2),fout)
    os.system("1d_tool.py -overwrite -infile "+iname+'['+str(col1)+".."+str(col2)+"] -write "+oname)
    
def final_bvecs_1(eddy,data,volsPos1,volsPos2,volsNeg1,volsNeg2,fout):
    echo("**All series are present**",fout)
    trimCols(0,volsPos1-1,eddy+"eddy_unwarped_images.eddy_rotated_bvecs",data+"rm_pos1",fout)
    trimCols(volsPos1,volsPos1+volsPos2-1,eddy+"eddy_unwarped_images.eddy_rotated_bvecs",data+"rm_pos2",fout)
    trimCols(volsPos1+volsPos2,volsPos1+volsPos2+volsNeg1-1,eddy+"eddy_unwarped_images.eddy_rotated_bvecs",data+"rm_neg1",fout)
    trimCols(volsPos1+volsPos2+volsNeg1,volsPos1+volsPos2+volsNeg1+volsNeg2-1,eddy+"eddy_unwarped_images.eddy_rotated_bvecs",data+"rm_neg2",fout)
        
    # Average the vectors
    pos1 = open(data+"rm_pos1",'r')
    pos2 = open(data+"rm_pos2",'r')
    neg1 = open(data+"rm_neg1",'r')
    neg2 = open(data+"rm_neg2",'r')
    out = open(data+"bvecs",'w')
    for i in range(3):
        p1 = list(map(float, pos1.readline().replace('\n','').split(' ')))
        p2 = list(map(float, pos2.readline().replace('\n','').split(' ')))
        n1 = list(map(float, neg1.readline().replace('\n','').split(' ')))
        n2 = list(map(float, neg2.readline().replace('\n','').split(' ')))
        avg1 = [(g + h) / 2 for g, h in zip(p1, n1)]
        avg2 = [(g + h) / 2 for g, h in zip(p2, n2)]
        for val in avg1:
            out.write(str(val)+' ')
        for val in avg2:
            out.write(str(val)+' ')
        out.write('\n')
    out.close()
    neg2.close()
    neg1.close()
    pos2.close()
    pos1.close()
    
    # Delete temporary files
    os.remove(data+"rm_pos1")
    os.remove(data+"rm_pos2")
    os.remove(data+"rm_neg1")
    os.remove(data+"rm_neg2")

def final_bvecs_2(eddy,data,volsPos1,volsNeg1,fout):
    echo("**Only 75 series are present: average PA1 and AP1 bvecs**",fout)
    trimCols(0,volsPos1-1,eddy+"eddy_unwarped_images.eddy_rotated_bvecs",data+"rm_pos1",fout)
    trimCols(volsPos1,volsPos1+volsNeg1-1,eddy+"eddy_unwarped_images.eddy_rotated_bvecs",data+"rm_neg1",fout)
        
    # Average the vectors
    pos1 = open(data+"rm_pos1",'r')
    neg1 = open(data+"rm_neg1",'r')
    out = open(data+"bvecs",'w')
    for i in range(3):
        p1 = list(map(float, pos1.readline().replace('\n','').split(' ')))
        n1 = list(map(float, neg1.readline().replace('\n','').split(' ')))
        avg1 = [(g + h) / 2 for g, h in zip(p1, n1)]
        for val in avg1:
            out.write(str(val)+' ')
        out.write('\n')
    out.close()
    neg1.close()
    pos1.close()
    
    # Delete temporary files
    os.remove(data+"rm_pos1")
    os.remove(data+"rm_neg1")
    
def final_bvecs_3(eddy,data,volsPos2,volsNeg2,fout):
    echo("**Only 76 series are present: average PA2 and AP2 bvecs**",fout)
    trimCols(0,volsPos2-1,eddy+"eddy_unwarped_images.eddy_rotated_bvecs",data+"rm_pos2",fout)
    trimCols(volsPos2,volsPos2+volsNeg2-1,eddy+"eddy_unwarped_images.eddy_rotated_bvecs",data+"rm_neg2",fout)
        
    # Average the vectors
    pos2 = open(data+"rm_pos2",'r')
    neg2 = open(data+"rm_neg2",'r')
    out = open(data+"bvecs",'w')
    for i in range(3):
        p2 = list(map(float, pos2.readline().replace('\n','').split(' ')))
        n2 = list(map(float, neg2.readline().replace('\n','').split(' ')))
        avg2 = [(g + h) / 2 for g, h in zip(p2, n2)]
        for val in avg2:
            out.write(str(val)+' ')
        out.write('\n')
    out.close()
    neg2.close()
    pos2.close()
    
    # Delete temporary files
    os.remove(data+"rm_pos2")
    os.remove(data+"rm_neg2")
    
def nvols(filepath):
    if os.path.isfile(filepath):
        return int(os.popen("fslval "+filepath+" dim4").read().replace('\n','').replace(' ',''))
    else:
        return 0
         
def run(sbj):
    start_time = str(datetime.datetime.today().strftime("%H:%M:%S"))
    fout = open("postEddy_nohup.out",'w')
    echo("Running postEddy on "+sbj+"...",fout)
    
    sbjDir = "/group/jbinder/ECP/Data_Release/"+sbj+"/Diffusion_clean_v2/"
    eddy = sbjDir+"eddy/"
    data = sbjDir+"data/"
    topup = sbjDir+"topup/"
    preddy = sbjDir+"preEddy/"
    
    if os.path.isdir(data):
        os.system("rm -r "+data) 
    os.mkdir(data)
        
    ### Get the number of volumes for each series ###
    echo("1. Getting the number of volumes for each series...",fout)
    volsPos1 = int(nvols(preddy+"PA_1.nii.gz"))
    volsPos2 = int(nvols(preddy+"PA_2.nii.gz"))
    volsNeg1 = int(nvols(preddy+"AP_1.nii.gz"))
    volsNeg2 = int(nvols(preddy+"AP_2.nii.gz"))
    echo("75PA,76PA,75AP,76AP: "+str(volsPos1)+','+str(volsPos2)+','+str(volsNeg1)+','+str(volsNeg2),fout)
    
    #### Trim the bvals ####
    echo("2. Creating final bvals...",fout)
    # All series are present
    if volsPos1>0 and volsPos2>0 and volsNeg1>0 and volsNeg2>0:
        trimCols(0,volsPos1+volsPos2-1,eddy+"Pos_Neg.bval",data+"bvals",fout)
    elif volsPos1>0 and volsNeg1>0:
        # Only 75 series are present
        if volsPos2==0 and volsNeg2==0:
            trimCols(0,volsPos1-1,eddy+"Pos_Neg.bval",data+"bvals",fout)
        # Not all images are paired
        else:
            echo("Not all images are paired",fout)
            os.system("cp "+eddy+"Pos_Neg.bval "+data+"bvals")
    elif volsPos2>0 and volsNeg2>0:
        # Only 76 series are present
        if volsPos1==0 and volsNeg1==0:
            trimCols(0,volsPos2-1,eddy+"Pos_Neg.bval",data+"bvals",fout)
        # Not all images are paired
        else:
            echo("Not all images are paired",fout)
            os.system("cp "+eddy+"Pos_Neg.bval "+data+"bvals")
    # Images are not paired
    else:
        echo("Not all images are paired",fout)
        os.system("cp "+eddy+"Pos_Neg.bval "+data+"bvals")
    
    ### Get the average of the rotated bvecs ####
    # Separate the bvecs for each series
    echo("3. Creating final bvecs...",fout)
    
    # All series are present
    if volsPos1>0 and volsPos2>0 and volsNeg1>0 and volsNeg2>0:
        final_bvecs_1(eddy,data,volsPos1,volsPos2,volsNeg1,volsNeg2,fout)
    elif volsPos1>0 and volsNeg1>0:
        # Only 75 series are present
        if volsPos2==0 and volsNeg2==0:
            final_bvecs_2(eddy,data,volsPos1,volsNeg1,fout)
        # Not all images are paired
        else:
            echo("Not all images are paired",fout)
            os.system("cp "+eddy+"eddy_unwarped_images.eddy_rotated_bvecs "+data+"bvecs")
    elif volsPos2>0 and volsNeg2>0:
        # Only 76 series are present
        if volsPos1==0 and volsNeg1==0:
            final_bvecs_3(eddy,data,volsPos2,volsNeg2,fout)
        # Not all images are paired
        else:
            echo("Not all images are paired",fout)
            os.system("cp "+eddy+"eddy_unwarped_images.eddy_rotated_bvecs "+data+"bvecs")
    # Images are not paired
    else:
        echo("Not all images are paired",fout)
        os.system("cp "+eddy+"eddy_unwarped_images.eddy_rotated_bvecs "+data+"bvecs")
    
    #### Remove negative intensity values (caused by spline interpolation) from final data ####
    echo("4. Removing negative intensity values..",fout)
    os.system("fslmaths "+eddy+"eddy_unwarped_images -thr 0 "+data+"data")
    echo("Creating masked file...",fout)
    os.system("cp "+topup+"nodif_brain_mask.nii.gz "+data)
    os.system("fslmaths "+data+"data -mul "+data+"nodif_brain_mask "+data+"nodif_brain")
    echo("Creating nodif...",fout)
    os.system("fslroi "+data+"data "+data+"nodif 0 1")
    
    echo("DONE postEddy",fout)
    end_time = str(datetime.datetime.today().strftime("%H:%M:%S"))
    tdelta = str(datetime.datetime.strptime(end_time,"%H:%M:%S") - datetime.datetime.strptime(start_time,"%H:%M:%S")).split(':')
    hr = tdelta[0]
    if hr=='0':
        hr = "00"
    mn = tdelta[1]
    if mn =='0':
        mn = "00"
    sc = tdelta[2]
    if sc=='0':
        sc = "00"
    echo("Total execution time was "+hr+" hrs "+mn+" mins "+sc+" secs",fout)
    fout.close()

def main():
    if len(sys.argv)!=2:
        sys.exit("Wrong number of arguments")
    sbj = sys.argv[1]
    run(sbj)

if __name__ == "__main__":
        main()
