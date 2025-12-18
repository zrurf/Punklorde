package hacker.silverwolf.punklorde
import com.baidu.mapapi.base.BmfMapApplication
import com.baidu.mapapi.CoordType
import com.baidu.mapapi.SDKInitializer

class MainApplication: BmfMapApplication() {
    override fun onCreate() {
        super.onCreate()

        BmfMapApplication.mContext = applicationContext
        
        SDKInitializer.setAgreePrivacy(this, true)
        SDKInitializer.setCoordType(CoordType.GCJ02)
        SDKInitializer.initialize(this)
    }
}