package com.pgy.xhamap

import android.Manifest
import android.app.Activity
import androidx.appcompat.app.AlertDialog
import com.karumi.dexter.Dexter
import com.karumi.dexter.MultiplePermissionsReport
import com.karumi.dexter.PermissionToken
import com.karumi.dexter.listener.PermissionRequest
import com.karumi.dexter.listener.multi.MultiplePermissionsListener
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import android.util.Log
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.karumi.dexter.listener.PermissionDeniedResponse
import com.karumi.dexter.listener.PermissionGrantedResponse
import com.karumi.dexter.listener.single.PermissionListener

/**
 * Runtime权限申请
 */
class PermissionManager {

    companion object {
        const val TAG = "PermissionManager"

//        const val PERMISSION_REQUEST_CODE = 110

        fun checkMulti(activity: Activity,
                       permissions: Array<String>,
                       isForceGrant: Boolean = true,
                       disallow: () -> Unit = {},
                       permissionName: String? = null,
                       allPermissionGranted: () -> Unit) {
//            Log.d("PermissionManager", "checkMulti")
            if (hasAllPermissions(activity, permissions)) {
                allPermissionGranted()
                return
            } else {
//                if (isForceGrant) {
//                    Toast.makeText(activity, "您没有${permissionName ?: "相关"}权限", Toast.LENGTH_SHORT).show()
//                }
            }

            Dexter.withActivity(activity)
                .withPermissions(permissions.asList())
                .withListener(object : MultiplePermissionsListener {
                    override fun onPermissionsChecked(report: MultiplePermissionsReport?) {
//                        Log.d("PermissionManager", "onPermissionsChecked: ${report?.areAllPermissionsGranted()}")
                        if (report?.areAllPermissionsGranted() == true) {
                            // 所有权限可用
                            allPermissionGranted()
                        } else {
                            disallow()
                        }
                        if (report?.isAnyPermissionPermanentlyDenied == true && isForceGrant) {
//                            CommonUtils.showToast(activity, "您的${permissionName ?: ""}权限被禁用了，请在系统设置中打开")
                            AlertDialog.Builder(activity)
                                .setCancelable(false)
                                .setMessage("尊敬的用户，您的${permissionName.orEmpty()}权限被禁用了，请在系统设置中打开")
                                .setPositiveButton("打开") { _, _ ->
                                    // 所有权限被永久限制，打开系统设置
//                                    SystemUtils.openSettingsPermission(activity)
                                }
                                .setNegativeButton("取消", null)
                                .show()
                        }
                    }

                    override fun onPermissionRationaleShouldBeShown(
                        permissions: MutableList<PermissionRequest>?,
                        token: PermissionToken?
                    ) {
//                        Log.d("PermissionManager", "onPermissionRationaleShouldBeShown: ${permissions}")

                        if (isForceGrant) {
                            // 有权限被禁止，提示用户授权
                            AlertDialog.Builder(activity)
                                .setCancelable(false)
                                .setMessage("尊敬的用户，为保证App的正常使用，需要您授予${permissionName ?: "相关"}权限。")
                                .setPositiveButton("授予权限") { _, _ ->
                                    token?.continuePermissionRequest()
                                }
                                .setNegativeButton("取消") { _, _ ->
                                    token?.cancelPermissionRequest()
                                }
                                .show()
                        } else {
                            token?.cancelPermissionRequest()
                        }
                    }
                })
                .check()
        }

        fun checkSingle(activity: Activity, permission: String,
                        permissionName: String? = null,
                        isForceGrant: Boolean = true,
                        permissionGrant: () -> Unit) {
            if (hasPermission(activity, permission)) {
                permissionGrant()
                return
            } else {
//                if (isForceGrant) {
//                    CommonUtils.showToast(activity, "您没有${permissionName ?: "相关"}权限")
//                }
            }

            Dexter.withActivity(activity)
                .withPermission(permission)
                .withListener(object : PermissionListener {
                    override fun onPermissionGranted(response: PermissionGrantedResponse?) {
//                        Log.d("checkSingle", "onPermissionGranted")
                        permissionGrant()
                    }

                    override fun onPermissionRationaleShouldBeShown(
                        permission: PermissionRequest?,
                        token: PermissionToken?
                    ) {
//                        Log.d("checkSingle", "onPermissionRationaleShouldBeShown")
                        if (isForceGrant) {
                            // 有权限被禁止，提示用户授权
                            AlertDialog.Builder(activity)
                                .setCancelable(false)
                                .setMessage("尊敬的用户，为保证App的正常使用，需要您授予${permissionName ?: "相关"}权限。")
                                .setPositiveButton("授予权限") { _, _ ->
                                    token?.continuePermissionRequest()
                                }
                                .setNegativeButton("取消") { _, _ ->
                                    token?.cancelPermissionRequest()
                                }
                                .show()
                        } else {
                            token?.cancelPermissionRequest()
                        }
                    }

                    override fun onPermissionDenied(response: PermissionDeniedResponse?) {
//                        Log.d("checkSingle", "onPermissionDenied")
                        if (isForceGrant) {
                            Toast.makeText(activity, "您的${permissionName.orEmpty()}权限被禁用了，请在系统设置中打开", Toast.LENGTH_SHORT).show()
                            // 所有权限被永久限制，打开系统设置
                            val intent = Intent()
                            intent.action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                            val uri = Uri.fromParts("package", activity.packageName, null)
                            intent.data = uri
                            activity.startActivity(intent)
                        }
                    }
                })
                .check()
        }

        private fun hasAllPermissions(activity: Activity, permissions: Array<String>) : Boolean {
            var hasAllPermissions = true
            permissions.forEach {  permission ->
                if (!hasPermission(activity, permission)) {
                    hasAllPermissions = false
                }
            }
            return hasAllPermissions
        }

        private fun hasPermission(activity: Activity, permission: String) : Boolean {
            return ContextCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED
        }
    }
}