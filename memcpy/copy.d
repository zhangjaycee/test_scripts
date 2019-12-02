#! /usr/bin/bpftrace

// profiling the single threaded memcpy
uprobe:/home/zjc/test/cbdma/a.out:memcpy_single 
{
    //clear(@st);
    @st = nsecs; 
    @cnt = count();
} 
uretprobe:/home/zjc/test/cbdma/a.out:memcpy_single 
/@st/
{ 
    printf("time: %ld us\n", (nsecs - @st) / 1000); 
    @myhist = lhist((nsecs - @st) / 1000, 0, 1000, 10);  
    //@myhist = hist(nsecs - @st);  
    clear(@st);
}

// profiling the multi-threaded memcpy
uprobe:/home/zjc/test/cbdma/a.out:memcpy_mt
{
    //clear(@st_mt);
    @st_mt = nsecs; 
    @cnt_mt = count();
} 
uretprobe:/home/zjc/test/cbdma/a.out:memcpy_mt
/@st_mt/
{ 
    printf("time: %ld us\n", (nsecs - @st_mt) / 1000); 
    @myhist_mt = lhist((nsecs - @st_mt) / 1000, 0, 1000, 10);  
    //@myhist_mt = hist(nsecs - @st_mt);  
    clear(@st_mt);
}
