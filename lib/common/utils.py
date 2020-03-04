import subprocess
import os

VNFM_ARTIFACTORY_URL = "https://rcplc7artent.genband.com/artifactory/vnfm-generic-prod-plano"
WORKSPACE = os.path.dirname(__file__)[:-11]

class Utils:

    def sourceTenant(cloud, tenant):
        cmd='source /AUTHEN_FILE/{0}/{1}-openrc.sh'.format(cloud, tenant)
        subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True).communicate()

    def getLastSuccesfulBuild(product_release):
        cmd='curl -sS "{url}/{rel}/Artifacts/lastSuccessfulBuild/heatTemplates/" | grep -E \'href="([^"#]+)"\' |  cut \'-d"\' -f2 | grep Ribbon_VNFM_Heat_Install | awk -F\'_\' \'{{ print $5}}\' | awk -F\'-\' \'{{print $2}}\' | awk -F\'.\' \'{{print $1}}\''.format(url=VNFM_ARTIFACTORY_URL, rel=product_release)
        build_number = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True).communicate()[0].decode("utf-8")
        return 'Build-{0}'.format(build_number)
    
    def getImageName(image_type, product_release, build_number):
        cmd='curl -sS "{url}/{rel}/Artifacts/{build}/" | grep -E \'href="([^"#]+)"\' |  cut \'-d"\' -f2 | grep {type})'.format(url=VNFM_ARTIFACTORY_URL, rel=product_release, build=build_number, type=image_type)
        image_name = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True).communicate()[0].decode("utf-8")
        return image_name

    apiEndpoints={
        "OTT-PC1" :
        {
            "keystone"  : "http://172.28.220.15:5000",
            "nova"      : "http://172.28.220.17:8774",
            "glance"    : "http://172.28.220.16:9292",
            "neutron"   : "http://172.28.220.18:9696",
            "cinder"    : "http://172.28.220.14:8776"
        },
        "OTT-PC2" :
        {
            "keystone"  : "http://172.28.220.15:5000",
            "nova"      : "http://172.28.220.17:8774",
            "glance"    : "http://172.28.220.16:9292",
            "neutron"   : "http://172.28.220.18:9696",
            "cinder"    : "http://172.28.220.14:8776"
        },
        "WFD-PC2" :
        {
            "keystone"  : "http://172.28.220.15:5000",
            "nova"      : "http://172.28.220.17:8774",
            "glance"    : "http://172.28.220.16:9292",
            "neutron"   : "http://172.28.220.18:9696",
            "cinder"    : "http://172.28.220.14:8776"
        },
        "PLA-PC2" :
        {
            "keystone"  : "http://172.28.220.15:5000",
            "nova"      : "http://172.28.220.17:8774",
            "glance"    : "http://172.28.220.16:9292",
            "neutron"   : "http://172.28.220.18:9696",
            "cinder"    : "http://172.28.220.14:8776"
        },
        "TMA" :
        {
            "keystone"  : "http://172.28.220.15:5000",
            "nova"      : "http://172.28.220.17:8774",
            "glance"    : "http://172.28.220.16:9292",
            "neutron"   : "http://172.28.220.18:9696",
            "cinder"    : "http://172.28.220.14:8776"
        }
    }