

#include <sys/time.h>
#include <sys/resource.h>

#include "omxplayer.hpp"


#include <iostream>
#include <vector>
#include <fstream>
#include <chrono>
#include <iomanip>


void printMemUsage() {
    
    struct rusage usage;

    getrusage(RUSAGE_SELF, &usage);

    std::cout << "=== [Memory usage]: >>>\u001b[33;1m" << usage.ru_maxrss << " KB\u001b[0m<<<" << std::endl;

    std::ofstream outfile;
    auto timestamp = std::chrono::system_clock::now();
    std::time_t now_tt = std::chrono::system_clock::to_time_t(timestamp);
    std::tm tm = *std::localtime(&now_tt);
    outfile.open("rss.txt", std::ios_base::app); // append instead of overwrite
    outfile << "[" << std::put_time(&tm, "%c %Z") << "] " << usage.ru_maxrss << '\n';; 
    outfile.close();
}

// "/home/pi/dev/isignale/src/res/videos/amazon.mp4"

struct iOMXPlayer {
    OMXPlayer_t oply;

    iOMXPlayer(std::string file) {
        std::cout << "New Object" << std::endl;
        oply.m_filename = file;
        oply.m_config_video.dst_rect = CRect{ 0, 0, 1920, 1080 };
        oply.m_config_video.display = 7;
        oply.m_config_video.layer = 20;
    }

    void init() {
        std::cout << "Init" << std::endl;
        oply.initialise();
        oply.openNewMedia();
    }

    ~iOMXPlayer() {
        std::cout << "Delete Object" << std::endl;
    }
};

int main1(int argc, char *argv[]) {

    iOMXPlayer omxplayer1(argv[1]);
    omxplayer1.oply.initialise();


    omxplayer1.oply.openNewMedia();

    omxplayer1.oply.startPlayer();
    std::this_thread::sleep_for(std::chrono::seconds(36));
    omxplayer1.oply.close();


    return 0;
}

int main() {

    iOMXPlayer *  omxplayer1 = new iOMXPlayer("/home/pi/dev/isignale/src/res/videos/amazon.mp4");
    omxplayer1->init();
    
    iOMXPlayer *  omxplayer2{nullptr};

    while( true ) {

        omxplayer1->oply.startPlayer();

        if(omxplayer2) {
            omxplayer2->oply.close();
            delete omxplayer2;
        }

        omxplayer2 = new iOMXPlayer("/home/pi/dev/isignale/src/res/videos/minion.mp4");
        omxplayer2->init();

        std::this_thread::sleep_for(std::chrono::seconds(10));
        omxplayer2->oply.startPlayer();
        omxplayer1->oply.close();
        delete omxplayer1;

        
        omxplayer1 = new iOMXPlayer("/home/pi/dev/isignale/src/res/videos/Sample_video_1__1_.mp4");
        omxplayer1->init();
        std::this_thread::sleep_for(std::chrono::seconds(10));

        printMemUsage();
    }

    return 0;
}