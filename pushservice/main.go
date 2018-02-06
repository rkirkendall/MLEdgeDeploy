package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis"
	_ "github.com/heroku/x/hmetrics/onload"
	"gopkg.in/yaml.v2"

	"github.com/sideshow/apns2"
	"github.com/sideshow/apns2/certificate"
	"github.com/sideshow/apns2/payload"
)

func main() {
	port := os.Getenv("PORT")

	if port == "" {
		log.Fatal("$PORT must be set")
	}

	db := redis.NewClient(&redis.Options{
		Addr:     "grouper.redistogo.com:10875",
		Password: "", // no password set
		DB:       0,  // use default DB
	})

	router := gin.New()
	router.Use(gin.Logger())

	router.POST("/deploy", func(c *gin.Context) {
		getMetdata(db)
		c.String(http.StatusOK, "")
	})

	// Handle Push tokens

	router.POST("/push/ios", func(c *gin.Context) {
		t := c.PostForm("token")

		db.SAdd("tokens", t)
		c.String(http.StatusOK, t)
	})

	router.GET("/push/ios", func(c *gin.Context) {

		output := ""

		iter := db.SScan("tokens", 0, "", 0).Iterator()
		for iter.Next() {
			output = fmt.Sprintf("%s %s", output, iter.Val())
		}
		if err := iter.Err(); err != nil {
			panic(err)
		}

		c.String(http.StatusOK, output)
	})

	router.GET("/push/clear", func(c *gin.Context) {
		db.Del("tokens")
		db.Del("lastRating")
		c.String(http.StatusOK, db.SCard("tokens").String())
	})

	router.Run(":" + port)
}

func getMetdata(db *redis.Client) {
	// Get metadata

	url := ""
	payload := strings.NewReader("")
	req, _ := http.NewRequest("GET", url, payload)
	res, _ := http.DefaultClient.Do(req)
	defer res.Body.Close()
	body, _ := ioutil.ReadAll(res.Body)

	m := make(map[interface{}]interface{})
	err := yaml.Unmarshal(body, &m)
	if err != nil {
		log.Fatalf("error: %v", err)
	}
	fmt.Printf("--- m:\n%v\n\n", m)

	lastRating, _ := db.Get("lastRating").Result()
	lrf, _ := strconv.ParseFloat(lastRating, 64)
	currentRating := m["rating"].(float64)
	threshf := m["thresh"].(float64)

	improvement := currentRating - lrf

	log.Printf("%f - %f =  %f :: Thresh: %f", currentRating, lrf, improvement, threshf)

	if improvement >= threshf {
		log.Println("Threshold for improvement met. Deploying model")

		iOSPush(db)

	} else {
		log.Println("Threshold NOT met")
	}

	db.Set("lastRating", m["rating"], 0)

}

func iOSPush(db *redis.Client) {
	cert, err := certificate.FromP12File("mlh-demo-dev-cert.p12", "")
	if err != nil {
		log.Fatal("Cert Error:", err)
	}

	iter := db.SScan("tokens", 0, "", 0).Iterator()
	for iter.Next() {
		token := iter.Val()
		notification := &apns2.Notification{}
		notification.DeviceToken = token
		notification.Topic = "com.mlhub.demo"
		coremlModelURL := ""
		payload := payload.NewPayload().Alert("New Model").Badge(0).Custom("dl", coremlModelURL)
		notification.Payload = payload

		client := apns2.NewClient(cert).Development()
		res, err := client.Push(notification)

		if err != nil {
			log.Fatal("Error:", err)
		}

		fmt.Printf("%v %v %v\n", res.StatusCode, res.ApnsID, res.Reason)
	}
	if err := iter.Err(); err != nil {
		panic(err)
	}
}
