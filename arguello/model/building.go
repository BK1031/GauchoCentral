package model

import "time"

type Building struct {
	ID          string    `gorm:"primaryKey" json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Latitude    float64   `json:"latitude"`
	Longitude   float64   `json:"longitude"`
	UpdatedAt   time.Time `gorm:"autoUpdateTime" json:"updated_at"`
	CreatedAt   time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (Building) TableName() string {
	return "building"
}
