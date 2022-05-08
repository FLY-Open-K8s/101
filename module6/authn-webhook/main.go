package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"

	"github.com/google/go-github/github"
	"golang.org/x/oauth2"
	authentication "k8s.io/api/authentication/v1beta1"
)

// ApiServer 集成企业自身的认证服务（如：LDAP,AD,KeyStone）
// 将ApiServer的Request请求，转到企业自身的认证服务
// 认证成功，写入TokenReviewStatus，传给ApiServer
func main() {

	// 1. 接收 `/authenticate` 请求
	http.HandleFunc("/authenticate", func(w http.ResponseWriter, r *http.Request) {
		decoder := json.NewDecoder(r.Body)
		// 请求信息，解析为TokenReview
		var tr authentication.TokenReview
		err := decoder.Decode(&tr)
		// 解码失败，直接返回
		if err != nil {
			log.Println("[Error]", err.Error())
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"apiVersion": "authentication.k8s.io/v1beta1",
				"kind":       "TokenReview",
				"status": authentication.TokenReviewStatus{
					Authenticated: false,
				},
			})
			return
		}
		log.Print("receving request")
		// 2. 校验检查用户
		// 获取TokenReview中的token信息
		// 支持Oauth2协议，可以通过oauth2.StaticTokenSource获取
		ts := oauth2.StaticTokenSource(
			&oauth2.Token{AccessToken: tr.Spec.Token},
		)
		// 发送认证请求，这里模拟了GitHub的Personal Access Token
		tc := oauth2.NewClient(context.Background(), ts)
		client := github.NewClient(tc)
		user, _, err := client.Users.Get(context.Background(), "")
		// 认证失败
		if err != nil {
			log.Println("[Error]", err.Error())
			w.WriteHeader(http.StatusUnauthorized)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"apiVersion": "authentication.k8s.io/v1beta1",
				"kind":       "TokenReview",
				"status": authentication.TokenReviewStatus{
					Authenticated: false,
				},
			})
			return
		}
		log.Printf("[Success] login as %s", *user.Login)
		// 认证成功，写入TokenReviewStatus
		w.WriteHeader(http.StatusOK)
		trs := authentication.TokenReviewStatus{
			Authenticated: true,
			User: authentication.UserInfo{
				Username: *user.Login,
				UID:      *user.Login,
			},
		}
		json.NewEncoder(w).Encode(map[string]interface{}{
			"apiVersion": "authentication.k8s.io/v1beta1",
			"kind":       "TokenReview",
			"status":     trs,
		})
	})
	log.Println(http.ListenAndServe(":3000", nil))
}
