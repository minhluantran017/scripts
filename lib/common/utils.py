import subprocess
import os

VNFM_ARTIFACTORY_URL = "https://rcplc7artent.genband.com/artifactory/vnfm-generic-prod-plano"
WORKSPACE = os.path.dirname(__file__)[:-11]

class Utils:

    def sourceTenant(cloud, tenant):
        cmd='source /AUTHEN_FILE/{0}/{1}-openrc.sh'.format(cloud, tenant)
        subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True).communicate()

    def getLastSuccesfulBuild(product_release='mainline'):
        cmd='curl -sS "{url}/{rel}/Artifacts/lastSuccessfulBuild/heatTemplates/" | grep -E \'href="([^"#]+)"\' |  cut \'-d"\' -f2 | grep Ribbon_VNFM_Heat_Install | awk -F\'_\' \'{{ print $5}}\' | awk -F\'-\' \'{{print $2}}\' | awk -F\'.\' \'{{print $1}}\''.format(url=VNFM_ARTIFACTORY_URL, rel=product_release)
        build_number = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True).communicate()[0].decode("utf-8")
        return 'Build-{0}'.format(build_number)
    
    def getImageName(image_type, product_release='mainline', build_number):
        cmd='curl -sS "{url}/{rel}/Artifacts/{build}/" | grep -E \'href="([^"#]+)"\' |  cut \'-d"\' -f2 | grep {type})'.format(url=VNFM_ARTIFACTORY_URL, rel=product_release, build=build_number, type=image_type)
        image_name = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True).communicate()[0].decode("utf-8")
        return image_name

    def downloadHeatTemplate(topology='HA', product_release='mainline', build_number):
        if topology == 'HA':
            cmd='curl -sS -o {wp}/tmp/{build}/Ribbon_VNFM_Heat_Install.yaml "{url}/{rel}/Artifacts/{build}/heatTemplates/Ribbon_VNFM_Heat_Install*.yaml"'.format( wp=WORKSPACE, build=build_number,url=VNFM_ARTIFACTORY_URL, rel=product_release)
            subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True).communicate()
        else:
            cmd='curl -sS -o {wp}/tmp/{build}/Ribbon_VNFM_GR_Heat_Install.yaml "{url}/{rel}/Artifacts/{build}/heatTemplates/Ribbon_VNFM_GR_Heat_Install*.yaml"'.format( wp=WORKSPACE, build=build_number,url=VNFM_ARTIFACTORY_URL, rel=product_release)
            subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True).communicate()
        
    apiEndpoints={
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
            "keystone"  : "https://172.23.2.10:5000",
            "nova"      : "https://172.23.2.10:8774",
            "glance"    : "https://172.23.2.10:9292",
            "neutron"   : "https://172.23.2.10:9696",
            "cinder"    : "https://172.23.2.10:8776"
        },
        "PLA-PC2" :
        {
            "keystone"  : "https://pla-pc2.eng.sonusnet.com:13000",
            "nova"      : "https://pla-pc2.eng.sonusnet.com:13774",
            "glance"    : "https://pla-pc2.eng.sonusnet.com:13292",
            "neutron"   : "https://pla-pc2.eng.sonusnet.com:13696",
            "cinder"    : "https://pla-pc2.eng.sonusnet.com:13776"
        }
    }